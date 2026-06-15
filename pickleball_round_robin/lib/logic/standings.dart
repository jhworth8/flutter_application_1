import '../models/models.dart';

/// Computes live tournament standings from completed matches.
///
/// A player earns a win/loss for every scored match they played, and their
/// point differential accumulates `score(theirSide) - score(otherSide)` across
/// those matches. Records are kept even for players later toggled inactive so
/// end-of-day standings remain accurate (departures freeze, never erase).
class StandingsCalculator {
  static List<Standing> compute(
    List<Player> players,
    List<GameRound> rounds,
  ) {
    final wins = <String, int>{};
    final losses = <String, int>{};
    final diff = <String, int>{};

    for (final p in players) {
      wins[p.id] = 0;
      losses[p.id] = 0;
      diff[p.id] = 0;
    }

    void ensure(String id) {
      wins.putIfAbsent(id, () => 0);
      losses.putIfAbsent(id, () => 0);
      diff.putIfAbsent(id, () => 0);
    }

    for (final round in rounds) {
      for (final m in round.matches) {
        if (m.winner == null) continue;
        final aWon = m.winner == TeamSide.a;
        final marginA = m.scoreA - m.scoreB;

        for (final id in m.teamA) {
          ensure(id);
          diff[id] = diff[id]! + marginA;
          if (aWon) {
            wins[id] = wins[id]! + 1;
          } else {
            losses[id] = losses[id]! + 1;
          }
        }
        for (final id in m.teamB) {
          ensure(id);
          diff[id] = diff[id]! - marginA;
          if (aWon) {
            losses[id] = losses[id]! + 1;
          } else {
            wins[id] = wins[id]! + 1;
          }
        }
      }
    }

    final nameOf = {for (final p in players) p.id: p.name};

    final standings = wins.keys.map((id) {
      return Standing(
        playerId: id,
        name: nameOf[id] ?? '—',
        wins: wins[id]!,
        losses: losses[id]!,
        pointDifferential: diff[id]!,
      );
    }).toList();

    standings.sort((a, b) {
      if (b.wins != a.wins) return b.wins.compareTo(a.wins);
      if (b.pointDifferential != a.pointDifferential) {
        return b.pointDifferential.compareTo(a.pointDifferential);
      }
      // Fewer losses ranks higher, then alphabetical for stability.
      if (a.losses != b.losses) return a.losses.compareTo(b.losses);
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    return standings;
  }
}
