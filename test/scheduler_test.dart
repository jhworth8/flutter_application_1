import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:pickleball_round_robin/logic/scheduler.dart';
import 'package:pickleball_round_robin/models/models.dart';

List<Player> roster(int n) =>
    List.generate(n, (i) => Player(id: 'p${i + 1}', name: 'P${i + 1}'));

void main() {
  group('Scheduler structural guarantees', () {
    final scheduler = Scheduler(restarts: 200, random: Random(7));

    test('fills the right number of courts and benches the remainder', () {
      final players = roster(10); // 2 full courts, 2 benched.
      final result = scheduler.generateRound(
        roundNum: 1,
        activePlayers: players,
        courtsAvailable: 3,
        matrices: HistoryMatrices(),
      );
      final round = result.round;

      expect(round.matches.length, 2);
      expect(round.bench.length, 2);

      // Every player appears exactly once (on a court or the bench).
      final seen = <String>{};
      for (final m in round.matches) {
        seen.addAll(m.allPlayers);
        expect(m.teamA.length, 2);
        expect(m.teamB.length, 2);
      }
      seen.addAll(round.bench);
      expect(seen.length, 10);
    });

    test('first server is one of the four players on its court', () {
      final result = scheduler.generateRound(
        roundNum: 1,
        activePlayers: roster(4),
        courtsAvailable: 1,
        matrices: HistoryMatrices(),
      );
      final m = result.round.matches.single;
      expect(m.allPlayers.contains(m.firstServer), isTrue);
    });

    test('court count is capped by available players', () {
      final result = scheduler.generateRound(
        roundNum: 1,
        activePlayers: roster(5),
        courtsAvailable: 4,
        matrices: HistoryMatrices(),
      );
      expect(result.round.matches.length, 1); // only one full court possible
      expect(result.round.bench.length, 1);
    });

    test('returns everyone benched when a court cannot be filled', () {
      final result = scheduler.generateRound(
        roundNum: 1,
        activePlayers: roster(3),
        courtsAvailable: 2,
        matrices: HistoryMatrices(),
      );
      expect(result.round.matches, isEmpty);
      expect(result.round.bench.length, 3);
    });
  });

  group('Bye equity', () {
    test('nobody sits twice until everyone has sat once', () {
      final scheduler = Scheduler(restarts: 300, random: Random(3));
      final players = roster(5); // one benched per round.
      final matrices = HistoryMatrices();
      for (final p in players) {
        matrices.ensurePlayer(p.id);
      }

      // Play five rounds; commit each so byes accumulate.
      for (var r = 1; r <= 5; r++) {
        final round = scheduler
            .generateRound(
              roundNum: r,
              activePlayers: players,
              courtsAvailable: 1,
              matrices: matrices,
            )
            .round;
        Scheduler.commitRound(round, matrices);
      }

      // After 5 rounds with 5 players each sat exactly once.
      for (final p in players) {
        expect(matrices.byeCount(p.id), 1,
            reason: '${p.id} should have exactly one bye');
      }
    });
  });

  group('Partnership rotation', () {
    test('avoids repeating partners while options remain', () {
      final scheduler = Scheduler(restarts: 400, random: Random(11));
      final players = roster(4);
      final matrices = HistoryMatrices();

      // Round 1.
      final r1 = scheduler
          .generateRound(
            roundNum: 1,
            activePlayers: players,
            courtsAvailable: 1,
            matrices: matrices,
          )
          .round;
      Scheduler.commitRound(r1, matrices);

      // Round 2 should pick a different partnership split.
      final r2 = scheduler
          .generateRound(
            roundNum: 2,
            activePlayers: players,
            courtsAvailable: 1,
            matrices: matrices,
          )
          .round;

      final m1 = r1.matches.single;
      final m2 = r2.matches.single;
      final r1Pairs = {m1.teamA.toSet(), m1.teamB.toSet()};
      final repeated = r2.matches.any((m) =>
          r1Pairs.any((pair) => _setEquals(pair, m.teamA.toSet())) ||
          r1Pairs.any((pair) => _setEquals(pair, m.teamB.toSet())));
      expect(repeated, isFalse,
          reason: 'Round 2 reused a partnership from round 1');
      expect(m2.matches2v2Valid, isTrue);
    });
  });
}

bool _setEquals(Set<String> a, Set<String> b) =>
    a.length == b.length && a.containsAll(b);

extension on GameMatch {
  bool get matches2v2Valid => teamA.length == 2 && teamB.length == 2;
}
