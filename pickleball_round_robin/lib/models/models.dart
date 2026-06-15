// Core data models for the Pickleball Round Robin engine.
//
// Every model is plain Dart with hand-written JSON (de)serialization so the
// entire application state can be flattened to local storage on each mutation
// for crash recovery — no code generation required.

/// Scoring mode for a session.
enum ScoringMode {
  rally,
  sideOut;

  String get label => this == ScoringMode.rally ? 'Rally' : 'Side-Out';

  String toJson() => this == ScoringMode.rally ? 'RALLY' : 'SIDEOUT';

  static ScoringMode fromJson(String? raw) =>
      raw == 'SIDEOUT' ? ScoringMode.sideOut : ScoringMode.rally;
}

/// Which side of the net won a match.
enum TeamSide {
  a,
  b;

  String toJson() => this == TeamSide.a ? 'A' : 'B';

  static TeamSide? fromJson(String? raw) {
    if (raw == 'A') return TeamSide.a;
    if (raw == 'B') return TeamSide.b;
    return null;
  }
}

/// Default game parameters applied when a new session starts.
class Rules {
  final ScoringMode scoringMode;
  final int targetScore;
  final bool useTimer;
  final int timerDurationSeconds;

  const Rules({
    this.scoringMode = ScoringMode.rally,
    this.targetScore = 11,
    this.useTimer = false,
    this.timerDurationSeconds = 720,
  });

  Rules copyWith({
    ScoringMode? scoringMode,
    int? targetScore,
    bool? useTimer,
    int? timerDurationSeconds,
  }) {
    return Rules(
      scoringMode: scoringMode ?? this.scoringMode,
      targetScore: targetScore ?? this.targetScore,
      useTimer: useTimer ?? this.useTimer,
      timerDurationSeconds: timerDurationSeconds ?? this.timerDurationSeconds,
    );
  }

  Map<String, dynamic> toJson() => {
        'scoring_mode': scoringMode.toJson(),
        'target_score': targetScore,
        'use_timer': useTimer,
        'timer_duration_seconds': timerDurationSeconds,
      };

  factory Rules.fromJson(Map<String, dynamic> json) => Rules(
        scoringMode: ScoringMode.fromJson(json['scoring_mode'] as String?),
        targetScore: (json['target_score'] as num?)?.toInt() ?? 11,
        useTimer: json['use_timer'] as bool? ?? false,
        timerDurationSeconds:
            (json['timer_duration_seconds'] as num?)?.toInt() ?? 720,
      );
}

/// A single human participant. Lives in both the master roster cache and inside
/// an active session (the session keeps its own snapshot so departures freeze
/// historical performance cleanly).
class Player {
  final String id;
  final String name;
  final bool isActive;
  final int byes;

  const Player({
    required this.id,
    required this.name,
    this.isActive = true,
    this.byes = 0,
  });

  Player copyWith({String? name, bool? isActive, int? byes}) => Player(
        id: id,
        name: name ?? this.name,
        isActive: isActive ?? this.isActive,
        byes: byes ?? this.byes,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'is_active': isActive,
        'byes': byes,
      };

  factory Player.fromJson(Map<String, dynamic> json) => Player(
        id: json['id'] as String,
        name: json['name'] as String,
        isActive: json['is_active'] as bool? ?? true,
        byes: (json['byes'] as num?)?.toInt() ?? 0,
      );
}

/// One doubles match on a single court.
class GameMatch {
  final int courtIndex;
  final List<String> teamA;
  final List<String> teamB;
  final String firstServer;
  final TeamSide? winner;
  final int scoreA;
  final int scoreB;

  const GameMatch({
    required this.courtIndex,
    required this.teamA,
    required this.teamB,
    required this.firstServer,
    this.winner,
    this.scoreA = 0,
    this.scoreB = 0,
  });

  bool get isComplete => winner != null;

  List<String> get allPlayers => [...teamA, ...teamB];

  GameMatch copyWith({
    TeamSide? winner,
    bool clearWinner = false,
    int? scoreA,
    int? scoreB,
    String? firstServer,
  }) {
    return GameMatch(
      courtIndex: courtIndex,
      teamA: teamA,
      teamB: teamB,
      firstServer: firstServer ?? this.firstServer,
      winner: clearWinner ? null : (winner ?? this.winner),
      scoreA: scoreA ?? this.scoreA,
      scoreB: scoreB ?? this.scoreB,
    );
  }

  Map<String, dynamic> toJson() => {
        'court_index': courtIndex,
        'team_a': teamA,
        'team_b': teamB,
        'first_server': firstServer,
        'winner': winner?.toJson(),
        'score': {'team_a': scoreA, 'team_b': scoreB},
      };

  factory GameMatch.fromJson(Map<String, dynamic> json) {
    final score = (json['score'] as Map?)?.cast<String, dynamic>() ?? const {};
    return GameMatch(
      courtIndex: (json['court_index'] as num).toInt(),
      teamA: (json['team_a'] as List).cast<String>(),
      teamB: (json['team_b'] as List).cast<String>(),
      firstServer: json['first_server'] as String,
      winner: TeamSide.fromJson(json['winner'] as String?),
      scoreA: (score['team_a'] as num?)?.toInt() ?? 0,
      scoreB: (score['team_b'] as num?)?.toInt() ?? 0,
    );
  }
}

/// A generated round: a set of simultaneous matches plus the benched players.
class GameRound {
  final int roundNum;
  final bool isCompleted;
  final List<GameMatch> matches;
  final List<String> bench;

  const GameRound({
    required this.roundNum,
    this.isCompleted = false,
    required this.matches,
    required this.bench,
  });

  bool get allMatchesScored =>
      matches.isNotEmpty && matches.every((m) => m.isComplete);

  GameRound copyWith({
    bool? isCompleted,
    List<GameMatch>? matches,
    List<String>? bench,
  }) {
    return GameRound(
      roundNum: roundNum,
      isCompleted: isCompleted ?? this.isCompleted,
      matches: matches ?? this.matches,
      bench: bench ?? this.bench,
    );
  }

  Map<String, dynamic> toJson() => {
        'round_num': roundNum,
        'is_completed': isCompleted,
        'matches': matches.map((m) => m.toJson()).toList(),
        'bench': bench,
      };

  factory GameRound.fromJson(Map<String, dynamic> json) => GameRound(
        roundNum: (json['round_num'] as num).toInt(),
        isCompleted: json['is_completed'] as bool? ?? false,
        matches: (json['matches'] as List)
            .map((m) => GameMatch.fromJson((m as Map).cast<String, dynamic>()))
            .toList(),
        bench: (json['bench'] as List?)?.cast<String>() ?? const [],
      );
}

/// Historical pairing/opposition counters used by the scheduling cost function.
///
/// The partnership and opponent matrices are stored as symmetric nested maps
/// keyed by player id. The [byeArray] tracks how many rounds each player has
/// rested.
class HistoryMatrices {
  final Map<String, Map<String, int>> partnership;
  final Map<String, Map<String, int>> opponent;
  final Map<String, int> byeArray;

  HistoryMatrices({
    Map<String, Map<String, int>>? partnership,
    Map<String, Map<String, int>>? opponent,
    Map<String, int>? byeArray,
  })  : partnership = partnership ?? {},
        opponent = opponent ?? {},
        byeArray = byeArray ?? {};

  int partnershipCount(String a, String b) => partnership[a]?[b] ?? 0;

  int opponentCount(String a, String b) => opponent[a]?[b] ?? 0;

  int byeCount(String id) => byeArray[id] ?? 0;

  void _bump(Map<String, Map<String, int>> matrix, String a, String b) {
    matrix.putIfAbsent(a, () => {});
    matrix.putIfAbsent(b, () => {});
    matrix[a]![b] = (matrix[a]![b] ?? 0) + 1;
    matrix[b]![a] = (matrix[b]![a] ?? 0) + 1;
  }

  void recordPartnership(String a, String b) => _bump(partnership, a, b);

  void recordOpponent(String a, String b) => _bump(opponent, a, b);

  void recordBye(String id) => byeArray[id] = (byeArray[id] ?? 0) + 1;

  /// Ensures a player has an entry; used when injecting late arrivals.
  void ensurePlayer(String id, {int byes = 0}) {
    byeArray.putIfAbsent(id, () => byes);
  }

  HistoryMatrices clone() => HistoryMatrices(
        partnership: {
          for (final e in partnership.entries) e.key: Map<String, int>.from(e.value),
        },
        opponent: {
          for (final e in opponent.entries) e.key: Map<String, int>.from(e.value),
        },
        byeArray: Map<String, int>.from(byeArray),
      );

  static Map<String, dynamic> _matrixToJson(Map<String, Map<String, int>> m) =>
      {for (final e in m.entries) e.key: e.value};

  static Map<String, Map<String, int>> _matrixFromJson(dynamic raw) {
    if (raw is! Map) return {};
    return {
      for (final e in raw.entries)
        e.key as String: (e.value as Map).map(
          (k, v) => MapEntry(k as String, (v as num).toInt()),
        ),
    };
  }

  Map<String, dynamic> toJson() => {
        'partnership_matrix': _matrixToJson(partnership),
        'opponent_matrix': _matrixToJson(opponent),
        'bye_array': byeArray,
      };

  factory HistoryMatrices.fromJson(Map<String, dynamic> json) => HistoryMatrices(
        partnership: _matrixFromJson(json['partnership_matrix']),
        opponent: _matrixFromJson(json['opponent_matrix']),
        byeArray: (json['bye_array'] as Map?)?.map(
              (k, v) => MapEntry(k as String, (v as num).toInt()),
            ) ??
            {},
      );
}

/// The complete live tournament state — the serialized `active_session` blob.
class SessionState {
  final String sessionId;
  final String timestamp;
  final Rules rules;
  final List<Player> players;
  final int courtsAvailable;
  final int currentRoundIndex;
  final HistoryMatrices matrices;
  final List<GameRound> rounds;

  SessionState({
    required this.sessionId,
    required this.timestamp,
    required this.rules,
    required this.players,
    required this.courtsAvailable,
    required this.currentRoundIndex,
    required this.matrices,
    required this.rounds,
  });

  List<Player> get activePlayers =>
      players.where((p) => p.isActive).toList(growable: false);

  Player? playerById(String id) {
    for (final p in players) {
      if (p.id == id) return p;
    }
    return null;
  }

  String nameOf(String id) => playerById(id)?.name ?? '—';

  GameRound? get currentRound =>
      rounds.isEmpty ? null : rounds[rounds.length - 1];

  SessionState copyWith({
    Rules? rules,
    List<Player>? players,
    int? courtsAvailable,
    int? currentRoundIndex,
    HistoryMatrices? matrices,
    List<GameRound>? rounds,
  }) {
    return SessionState(
      sessionId: sessionId,
      timestamp: timestamp,
      rules: rules ?? this.rules,
      players: players ?? this.players,
      courtsAvailable: courtsAvailable ?? this.courtsAvailable,
      currentRoundIndex: currentRoundIndex ?? this.currentRoundIndex,
      matrices: matrices ?? this.matrices,
      rounds: rounds ?? this.rounds,
    );
  }

  Map<String, dynamic> toJson() => {
        'session_id': sessionId,
        'timestamp': timestamp,
        'rules': rules.toJson(),
        'players': players.map((p) => p.toJson()).toList(),
        'courts_available': courtsAvailable,
        'current_round_index': currentRoundIndex,
        'matrices': matrices.toJson(),
        'rounds': rounds.map((r) => r.toJson()).toList(),
      };

  factory SessionState.fromJson(Map<String, dynamic> json) => SessionState(
        sessionId: json['session_id'] as String,
        timestamp: json['timestamp'] as String,
        rules: Rules.fromJson((json['rules'] as Map).cast<String, dynamic>()),
        players: (json['players'] as List)
            .map((p) => Player.fromJson((p as Map).cast<String, dynamic>()))
            .toList(),
        courtsAvailable: (json['courts_available'] as num?)?.toInt() ?? 1,
        currentRoundIndex: (json['current_round_index'] as num?)?.toInt() ?? 0,
        matrices: HistoryMatrices.fromJson(
            (json['matrices'] as Map?)?.cast<String, dynamic>() ?? const {}),
        rounds: (json['rounds'] as List?)
                ?.map((r) =>
                    GameRound.fromJson((r as Map).cast<String, dynamic>()))
                .toList() ??
            [],
      );
}

/// A single row of computed tournament standings.
class Standing {
  final String playerId;
  final String name;
  final int wins;
  final int losses;
  final int pointDifferential;

  const Standing({
    required this.playerId,
    required this.name,
    required this.wins,
    required this.losses,
    required this.pointDifferential,
  });

  int get gamesPlayed => wins + losses;

  Map<String, dynamic> toJson() => {
        'player_id': playerId,
        'name': name,
        'wins': wins,
        'losses': losses,
        'point_differential': pointDifferential,
      };

  factory Standing.fromJson(Map<String, dynamic> json) => Standing(
        playerId: json['player_id'] as String? ?? '',
        name: json['name'] as String? ?? '—',
        wins: (json['wins'] as num?)?.toInt() ?? 0,
        losses: (json['losses'] as num?)?.toInt() ?? 0,
        pointDifferential: (json['point_differential'] as num?)?.toInt() ?? 0,
      );
}

/// An immutable record of a completed round-robin, kept in the session archive.
class ArchivedSession {
  final String id;
  final String date; // ISO-8601 timestamp.
  final int roundsPlayed;
  final List<Standing> standings;
  final List<GameRound> rounds;

  const ArchivedSession({
    required this.id,
    required this.date,
    required this.roundsPlayed,
    required this.standings,
    required this.rounds,
  });

  List<Standing> get podium => standings.take(3).toList();

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date,
        'rounds_played': roundsPlayed,
        'standings': standings.map((s) => s.toJson()).toList(),
        'rounds': rounds.map((r) => r.toJson()).toList(),
      };

  factory ArchivedSession.fromJson(Map<String, dynamic> json) => ArchivedSession(
        id: json['id'] as String,
        date: json['date'] as String,
        roundsPlayed: (json['rounds_played'] as num?)?.toInt() ?? 0,
        standings: (json['standings'] as List?)
                ?.map((s) =>
                    Standing.fromJson((s as Map).cast<String, dynamic>()))
                .toList() ??
            [],
        rounds: (json['rounds'] as List?)
                ?.map((r) =>
                    GameRound.fromJson((r as Map).cast<String, dynamic>()))
                .toList() ??
            [],
      );
}
