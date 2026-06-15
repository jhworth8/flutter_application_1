import 'dart:math';

import '../models/models.dart';

/// Result of generating a round: the round itself plus a description of the
/// final cost, useful for diagnostics / tests.
class ScheduleResult {
  final GameRound round;
  final double cost;

  const ScheduleResult({required this.round, required this.cost});
}

/// Constraint-based heuristic scheduling engine.
///
/// Generates round pairings by minimizing the penalty function:
///
///   E = w1 * Variance(B)
///     + w2 * Sum( max(0, P_ij - 1)^2 )      over proposed partnerships
///     + w3 * Sum( max(0, O_ij - 2)^2 )      over proposed oppositions
///
/// where P_ij / O_ij include the *proposed* pairing for this round and B is the
/// resulting per-player bye distribution. The dominant bye-variance weight
/// guarantees nobody sits twice until everyone has sat once.
class Scheduler {
  static const double wByeVariance = 1000;
  static const double wDuplicatePartner = 100;
  static const double wExcessiveOpponent = 10;

  /// Number of randomized restarts. Recreational sessions are small, so a few
  /// hundred restarts converge effectively instantly while reliably escaping
  /// poor local minima.
  final int restarts;
  final Random _random;

  Scheduler({this.restarts = 800, Random? random})
      : _random = random ?? Random();

  /// How many courts will actually be used given active players and the
  /// configured court count (each court needs exactly four players).
  static int courtsUsed(int activeCount, int courtsAvailable) {
    if (courtsAvailable <= 0) return 0;
    return min(courtsAvailable, activeCount ~/ 4);
  }

  /// Generates the next round. Does NOT mutate [matrices]; commit history
  /// separately via [commitRound] once the round is accepted.
  ScheduleResult generateRound({
    required int roundNum,
    required List<Player> activePlayers,
    required int courtsAvailable,
    required HistoryMatrices matrices,
  }) {
    final ids = activePlayers.map((p) => p.id).toList();
    final usedCourts = courtsUsed(ids.length, courtsAvailable);
    final playingCount = usedCourts * 4;
    final benchCount = ids.length - playingCount;

    // Degenerate case: not enough players for a single court.
    if (usedCourts == 0) {
      return ScheduleResult(
        round: GameRound(
          roundNum: roundNum,
          matches: const [],
          bench: List<String>.from(ids),
        ),
        cost: 0,
      );
    }

    _Arrangement? best;
    double bestCost = double.infinity;

    for (var attempt = 0; attempt < restarts; attempt++) {
      final arrangement = _buildArrangement(
        ids: ids,
        usedCourts: usedCourts,
        benchCount: benchCount,
        matrices: matrices,
      );
      final cost = _score(arrangement, ids, matrices);
      if (cost < bestCost) {
        bestCost = cost;
        best = arrangement;
        if (cost == 0) break; // Perfect schedule; no need to keep searching.
      }
    }

    final matches = <GameMatch>[];
    for (var c = 0; c < best!.courts.length; c++) {
      final court = best.courts[c];
      // Assign the first server deterministically-randomly among the four.
      final server = court.expand((t) => t).toList()[_random.nextInt(4)];
      matches.add(GameMatch(
        courtIndex: c + 1,
        teamA: court[0],
        teamB: court[1],
        firstServer: server,
      ));
    }

    return ScheduleResult(
      round: GameRound(
        roundNum: roundNum,
        matches: matches,
        bench: best.bench,
      ),
      cost: bestCost,
    );
  }

  /// Builds one candidate arrangement: pick a bench (favoring players with the
  /// fewest byes, randomizing ties), chunk the rest into courts of four, and
  /// within each court choose the 2v2 split that minimizes partnership cost.
  _Arrangement _buildArrangement({
    required List<String> ids,
    required int usedCourts,
    required int benchCount,
    required HistoryMatrices matrices,
  }) {
    // Order by current bye count ascending with a random tie-break so the
    // least-rested players are protected from sitting again.
    final ordered = List<String>.from(ids)
      ..sort((a, b) {
        final byeDiff = matrices.byeCount(a).compareTo(matrices.byeCount(b));
        if (byeDiff != 0) return byeDiff;
        return _random.nextInt(3) - 1;
      });

    // Bench the players with the fewest byes (it is their turn to rest); the
    // most-rested players keep playing. Ties are already randomized by the sort.
    final bench = ordered.sublist(0, benchCount);
    final playing = ordered.sublist(benchCount)..shuffle(_random);

    final courts = <List<List<String>>>[];
    for (var c = 0; c < usedCourts; c++) {
      final four = playing.sublist(c * 4, c * 4 + 4);
      courts.add(_bestSplit(four, matrices));
    }

    return _Arrangement(courts: courts, bench: bench);
  }

  /// Of the three ways to split four players into 2v2, pick the one whose
  /// teammates have partnered least often.
  List<List<String>> _bestSplit(List<String> four, HistoryMatrices matrices) {
    final splits = <List<List<String>>>[
      [
        [four[0], four[1]],
        [four[2], four[3]]
      ],
      [
        [four[0], four[2]],
        [four[1], four[3]]
      ],
      [
        [four[0], four[3]],
        [four[1], four[2]]
      ],
    ];

    List<List<String>>? best;
    var bestCost = double.infinity;
    for (final split in splits) {
      final cost = _partnerPenalty(split[0][0], split[0][1], matrices) +
          _partnerPenalty(split[1][0], split[1][1], matrices);
      if (cost < bestCost) {
        bestCost = cost;
        best = split;
      }
    }
    return best!;
  }

  double _partnerPenalty(String a, String b, HistoryMatrices matrices) {
    final proposed = matrices.partnershipCount(a, b) + 1;
    final excess = max(0, proposed - 1);
    return wDuplicatePartner * excess * excess;
  }

  double _opponentPenalty(String a, String b, HistoryMatrices matrices) {
    final proposed = matrices.opponentCount(a, b) + 1;
    final excess = max(0, proposed - 2);
    return wExcessiveOpponent * excess * excess;
  }

  /// Full penalty E for a candidate arrangement.
  double _score(
    _Arrangement arrangement,
    List<String> ids,
    HistoryMatrices matrices,
  ) {
    var cost = 0.0;

    // Partnership + opponent penalties.
    for (final court in arrangement.courts) {
      final teamA = court[0];
      final teamB = court[1];
      cost += _partnerPenalty(teamA[0], teamA[1], matrices);
      cost += _partnerPenalty(teamB[0], teamB[1], matrices);
      for (final a in teamA) {
        for (final b in teamB) {
          cost += _opponentPenalty(a, b, matrices);
        }
      }
    }

    // Bye-variance penalty over the resulting distribution.
    final benchSet = arrangement.bench.toSet();
    final newByes = <int>[];
    for (final id in ids) {
      newByes.add(matrices.byeCount(id) + (benchSet.contains(id) ? 1 : 0));
    }
    cost += wByeVariance * _variance(newByes);

    return cost;
  }

  double _variance(List<int> values) {
    if (values.isEmpty) return 0;
    final mean = values.reduce((a, b) => a + b) / values.length;
    var sum = 0.0;
    for (final v in values) {
      final d = v - mean;
      sum += d * d;
    }
    return sum / values.length;
  }

  /// Folds a generated round's pairings into the history matrices and bye array.
  /// Call this exactly once when a round is accepted/created.
  static void commitRound(GameRound round, HistoryMatrices matrices) {
    for (final m in round.matches) {
      matrices.recordPartnership(m.teamA[0], m.teamA[1]);
      matrices.recordPartnership(m.teamB[0], m.teamB[1]);
      for (final a in m.teamA) {
        for (final b in m.teamB) {
          matrices.recordOpponent(a, b);
        }
      }
    }
    for (final id in round.bench) {
      matrices.recordBye(id);
    }
  }
}

class _Arrangement {
  /// Each court is `[teamA, teamB]`, each team a list of two player ids.
  final List<List<List<String>>> courts;
  final List<String> bench;

  const _Arrangement({required this.courts, required this.bench});
}
