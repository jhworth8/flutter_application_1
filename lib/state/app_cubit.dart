import 'dart:math';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../logic/scheduler.dart';
import '../logic/standings.dart';
import '../models/models.dart';
import '../services/storage_service.dart';

/// Immutable top-level application state.
class AppData {
  /// Whether persisted state has finished loading.
  final bool loaded;

  /// Cached pool of all known players (the autocomplete / check-in roster).
  /// When no session is active this is the source the Launchpad edits.
  final List<Player> masterRoster;

  /// Court count chosen on the Launchpad before a session starts.
  final int pendingCourts;

  /// The live tournament, or null when sitting on the Launchpad.
  final SessionState? session;

  /// Completed tournaments.
  final List<ArchivedSession> archive;

  /// Default game parameters applied to new sessions.
  final Rules defaultRules;

  const AppData({
    this.loaded = false,
    this.masterRoster = const [],
    this.pendingCourts = 2,
    this.session,
    this.archive = const [],
    this.defaultRules = const Rules(),
  });

  bool get hasSession => session != null;

  AppData copyWith({
    bool? loaded,
    List<Player>? masterRoster,
    int? pendingCourts,
    Object? session = _noChange,
    List<ArchivedSession>? archive,
    Rules? defaultRules,
  }) {
    return AppData(
      loaded: loaded ?? this.loaded,
      masterRoster: masterRoster ?? this.masterRoster,
      pendingCourts: pendingCourts ?? this.pendingCourts,
      session: identical(session, _noChange)
          ? this.session
          : session as SessionState?,
      archive: archive ?? this.archive,
      defaultRules: defaultRules ?? this.defaultRules,
    );
  }

  static const _noChange = Object();
}

/// Single reactive state container. Every user-initiated mutation re-serializes
/// the relevant slices to local storage for instant crash recovery.
class AppCubit extends Cubit<AppData> {
  final StorageService _storage;
  final Scheduler _scheduler;
  final Random _random;

  AppCubit({StorageService? storage, Scheduler? scheduler, Random? random})
      : _storage = storage ?? StorageService(),
        _scheduler = scheduler ?? Scheduler(),
        _random = random ?? Random(),
        super(const AppData());

  // --- Lifecycle ----------------------------------------------------------

  Future<void> init() async {
    final roster = await _storage.loadMasterRoster();
    final session = await _storage.loadActiveSession();
    final archive = await _storage.loadArchive();
    final rules = await _storage.loadRules();
    emit(AppData(
      loaded: true,
      masterRoster: roster,
      session: session,
      archive: archive,
      defaultRules: rules,
      pendingCourts: session?.courtsAvailable ?? 2,
    ));
  }

  String _newId() {
    final stamp = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    final salt = _random.nextInt(1 << 20).toRadixString(36);
    return 'p_${stamp}_$salt';
  }

  // --- Launchpad: master roster editing -----------------------------------

  /// Adds a brand new player (checked-in) or re-checks-in an existing one by
  /// name. No-op on blank input.
  void addOrCheckInPlayer(String rawName) {
    final name = rawName.trim();
    if (name.isEmpty) return;

    final roster = List<Player>.from(state.masterRoster);
    final idx = roster.indexWhere(
        (p) => p.name.toLowerCase() == name.toLowerCase());
    if (idx >= 0) {
      roster[idx] = roster[idx].copyWith(isActive: true);
    } else {
      roster.add(Player(id: _newId(), name: name, isActive: true));
    }
    _commit(state.copyWith(masterRoster: roster));
  }

  /// Bulk-parses a comma / newline separated string into checked-in players.
  void addPlayersBulk(String blob) {
    final names = blob
        .split(RegExp(r'[,\n]'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty);
    final roster = List<Player>.from(state.masterRoster);
    for (final name in names) {
      final idx = roster.indexWhere(
          (p) => p.name.toLowerCase() == name.toLowerCase());
      if (idx >= 0) {
        roster[idx] = roster[idx].copyWith(isActive: true);
      } else {
        roster.add(Player(id: _newId(), name: name, isActive: true));
      }
    }
    _commit(state.copyWith(masterRoster: roster));
  }

  /// Toggles a player's check-in state on the Launchpad.
  void toggleCheckIn(String id) {
    final roster = state.masterRoster
        .map((p) => p.id == id ? p.copyWith(isActive: !p.isActive) : p)
        .toList();
    _commit(state.copyWith(masterRoster: roster));
  }

  /// Long-press delete: removes a player from the master database entirely.
  void deletePlayerFromRoster(String id) {
    final roster = state.masterRoster.where((p) => p.id != id).toList();
    _commit(state.copyWith(masterRoster: roster));
  }

  void setPendingCourts(int courts) {
    _commit(state.copyWith(pendingCourts: courts.clamp(1, 12)));
  }

  // --- Session lifecycle --------------------------------------------------

  /// Active checked-in players available to start a tournament.
  List<Player> get checkedInPlayers =>
      state.masterRoster.where((p) => p.isActive).toList();

  /// Begins a new round-robin from the checked-in roster. Returns false if
  /// there are not enough players to fill a single court.
  bool startRoundRobin() {
    final players = checkedInPlayers
        .map((p) => Player(id: p.id, name: p.name, isActive: true, byes: 0))
        .toList();
    if (players.length < 4) return false;

    final courts = state.pendingCourts.clamp(1, players.length ~/ 4);
    final matrices = HistoryMatrices();
    for (final p in players) {
      matrices.ensurePlayer(p.id);
    }

    final now = DateTime.now();
    final session = SessionState(
      sessionId:
          'sess_${now.toIso8601String().replaceAll(RegExp(r'[^0-9]'), '').substring(0, 14)}',
      timestamp: now.toUtc().toIso8601String(),
      rules: state.defaultRules,
      players: players,
      courtsAvailable: courts,
      currentRoundIndex: 0,
      matrices: matrices,
      rounds: const [],
    );

    final round = _scheduler
        .generateRound(
          roundNum: 1,
          activePlayers: players,
          courtsAvailable: courts,
          matrices: matrices,
        )
        .round;

    final started = session.copyWith(
      rounds: [round],
      currentRoundIndex: 1,
    );
    _commit(state.copyWith(session: started));
    return true;
  }

  // --- In-match scoring ---------------------------------------------------

  void setMatchWinner(int courtIndex, TeamSide side) {
    _mutateCurrentRound((round) {
      final matches = round.matches.map((m) {
        if (m.courtIndex != courtIndex) return m;
        // Provide sensible default scores the first time a side is tapped so
        // point differential is meaningful even without manual entry.
        var scoreA = m.scoreA;
        var scoreB = m.scoreB;
        if (scoreA == 0 && scoreB == 0) {
          final target = state.session!.rules.targetScore;
          scoreA = side == TeamSide.a ? target : 0;
          scoreB = side == TeamSide.b ? target : 0;
        }
        return m.copyWith(winner: side, scoreA: scoreA, scoreB: scoreB);
      }).toList();
      return round.copyWith(matches: matches);
    });
  }

  void setMatchScore(int courtIndex, {required int scoreA, required int scoreB}) {
    _mutateCurrentRound((round) {
      final matches = round.matches.map((m) {
        if (m.courtIndex != courtIndex) return m;
        final a = scoreA.clamp(0, 99);
        final b = scoreB.clamp(0, 99);
        TeamSide? winner = m.winner;
        if (a != b) winner = a > b ? TeamSide.a : TeamSide.b;
        return m.copyWith(scoreA: a, scoreB: b, winner: winner);
      }).toList();
      return round.copyWith(matches: matches);
    });
  }

  void _mutateCurrentRound(GameRound Function(GameRound) update) {
    final session = state.session;
    if (session == null || session.rounds.isEmpty) return;
    final rounds = List<GameRound>.from(session.rounds);
    rounds[rounds.length - 1] = update(rounds.last);
    _commit(state.copyWith(session: session.copyWith(rounds: rounds)));
  }

  /// Whether the current round is fully scored and the next can be generated.
  bool get canAdvance {
    final round = state.session?.currentRound;
    return round != null && round.allMatchesScored;
  }

  /// Finalizes the current round (committing its pairings to history) and
  /// generates the next one.
  void nextRound() {
    final session = state.session;
    if (session == null || session.rounds.isEmpty) return;

    final rounds = List<GameRound>.from(session.rounds);
    final completed = rounds.last.copyWith(isCompleted: true);
    rounds[rounds.length - 1] = completed;

    // Commit the finalized round into the (cloned) history matrices.
    final matrices = session.matrices.clone();
    Scheduler.commitRound(completed, matrices);

    // Keep per-player bye counts in sync for display.
    var players = session.players;
    if (completed.bench.isNotEmpty) {
      final benchSet = completed.bench.toSet();
      players = players
          .map((p) =>
              benchSet.contains(p.id) ? p.copyWith(byes: p.byes + 1) : p)
          .toList();
    }

    final active = players.where((p) => p.isActive).toList();
    final next = _scheduler
        .generateRound(
          roundNum: completed.roundNum + 1,
          activePlayers: active,
          courtsAvailable: session.courtsAvailable,
          matrices: matrices,
        )
        .round;
    rounds.add(next);

    _commit(state.copyWith(
      session: session.copyWith(
        rounds: rounds,
        players: players,
        matrices: matrices,
        currentRoundIndex: rounds.length,
      ),
    ));
  }

  /// Re-rolls the current (un-finalized) round — useful after a late arrival,
  /// early departure or court change.
  void regenerateCurrentRound() {
    final session = state.session;
    if (session == null || session.rounds.isEmpty) return;
    final rounds = List<GameRound>.from(session.rounds);
    final current = rounds.last;
    final active = session.players.where((p) => p.isActive).toList();
    final regenerated = _scheduler
        .generateRound(
          roundNum: current.roundNum,
          activePlayers: active,
          courtsAvailable: session.courtsAvailable,
          matrices: session.matrices,
        )
        .round;
    rounds[rounds.length - 1] = regenerated;
    _commit(state.copyWith(session: session.copyWith(rounds: rounds)));
  }

  // --- Mid-session "life happens" adjustments -----------------------------

  /// Injects a late arrival, backfilling synthetic byes equal to the number of
  /// rounds already played so the optimizer prioritizes them for active play.
  void addLatePlayer(String rawName) {
    final session = state.session;
    if (session == null) return;
    final name = rawName.trim();
    if (name.isEmpty) return;

    // Reuse an existing master-roster id/name if this person is known.
    final existing = state.masterRoster.firstWhere(
      (p) => p.name.toLowerCase() == name.toLowerCase(),
      orElse: () => Player(id: _newId(), name: name),
    );

    if (session.players.any((p) => p.id == existing.id)) {
      // Already in the session — just reactivate.
      togglePlayerActiveInSession(existing.id, forceActive: true);
      return;
    }

    final syntheticByes = session.rounds.length;
    final players = List<Player>.from(session.players)
      ..add(Player(
          id: existing.id, name: existing.name, isActive: true, byes: syntheticByes));

    final matrices = session.matrices.clone();
    matrices.byeArray[existing.id] = syntheticByes;

    // Ensure they also live in the master roster cache.
    final roster = List<Player>.from(state.masterRoster);
    if (!roster.any((p) => p.id == existing.id)) {
      roster.add(Player(id: existing.id, name: existing.name, isActive: true));
    }

    _commit(state.copyWith(
      masterRoster: roster,
      session: session.copyWith(players: players, matrices: matrices),
    ));
  }

  /// Toggles a player active/inactive mid-session. Inactive players are removed
  /// from upcoming allocation while their historical records stay frozen.
  void togglePlayerActiveInSession(String id, {bool? forceActive}) {
    final session = state.session;
    if (session == null) return;
    final players = session.players.map((p) {
      if (p.id != id) return p;
      return p.copyWith(isActive: forceActive ?? !p.isActive);
    }).toList();
    _commit(state.copyWith(session: session.copyWith(players: players)));
  }

  /// Dynamically alters available courts; takes effect on the next generation.
  void setSessionCourts(int courts) {
    final session = state.session;
    if (session == null) return;
    _commit(state.copyWith(
      session: session.copyWith(courtsAvailable: courts.clamp(1, 12)),
    ));
  }

  void updateSessionRules(Rules rules) {
    final session = state.session;
    if (session != null) {
      _commit(state.copyWith(session: session.copyWith(rules: rules)));
    }
  }

  void updateDefaultRules(Rules rules) {
    _commit(state.copyWith(defaultRules: rules));
  }

  // --- Standings & archive ------------------------------------------------

  List<Standing> currentStandings() {
    final session = state.session;
    if (session == null) return const [];
    return StandingsCalculator.compute(session.players, session.rounds);
  }

  /// Ends the session, archiving the completed tournament and returning to the
  /// Launchpad. Players remain checked-in for a fast re-start.
  void endSession() {
    final session = state.session;
    if (session == null) return;

    final standings =
        StandingsCalculator.compute(session.players, session.rounds);
    final completedRounds =
        session.rounds.where((r) => r.matches.any((m) => m.isComplete)).toList();

    final archived = ArchivedSession(
      id: session.sessionId,
      date: DateTime.now().toUtc().toIso8601String(),
      roundsPlayed: completedRounds.length,
      standings: standings,
      rounds: session.rounds,
    );

    final archive = [archived, ...state.archive];

    // Carry check-in state back to the master roster from the session.
    final sessionActive = {
      for (final p in session.players) p.id: p.isActive,
    };
    final roster = state.masterRoster
        .map((p) => sessionActive.containsKey(p.id)
            ? p.copyWith(isActive: sessionActive[p.id])
            : p)
        .toList();

    _commit(state.copyWith(
      session: null,
      archive: archive,
      masterRoster: roster,
    ));
  }

  /// Discards the active session without archiving.
  void discardSession() {
    _commit(state.copyWith(session: null));
  }

  void deleteArchivedSession(String id) {
    final archive = state.archive.where((a) => a.id != id).toList();
    _commit(state.copyWith(archive: archive));
  }

  // --- Persistence --------------------------------------------------------

  /// Emits new state and persists every slice. Persistence runs fire-and-forget
  /// so the UI stays instantly responsive while still being crash-durable.
  void _commit(AppData next) {
    emit(next);
    _persist(next);
  }

  Future<void> _persist(AppData data) async {
    await _storage.saveMasterRoster(data.masterRoster);
    await _storage.saveActiveSession(data.session);
    await _storage.saveArchive(data.archive);
    await _storage.saveRules(data.defaultRules);
  }
}
