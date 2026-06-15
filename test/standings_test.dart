import 'package:flutter_test/flutter_test.dart';
import 'package:pickleball_round_robin/logic/standings.dart';
import 'package:pickleball_round_robin/models/models.dart';

void main() {
  test('standings tally wins, losses and point differential', () {
    const players = [
      Player(id: 'a', name: 'Ana'),
      Player(id: 'b', name: 'Ben'),
      Player(id: 'c', name: 'Cal'),
      Player(id: 'd', name: 'Dee'),
    ];

    final rounds = [
      const GameRound(
        roundNum: 1,
        matches: [
          GameMatch(
            courtIndex: 1,
            teamA: ['a', 'b'],
            teamB: ['c', 'd'],
            firstServer: 'a',
            winner: TeamSide.a,
            scoreA: 11,
            scoreB: 7,
          ),
        ],
        bench: [],
      ),
    ];

    final standings = StandingsCalculator.compute(players, rounds);

    final ana = standings.firstWhere((s) => s.playerId == 'a');
    final cal = standings.firstWhere((s) => s.playerId == 'c');

    expect(ana.wins, 1);
    expect(ana.losses, 0);
    expect(ana.pointDifferential, 4);

    expect(cal.wins, 0);
    expect(cal.losses, 1);
    expect(cal.pointDifferential, -4);

    // Winners with positive differential rank above losers.
    expect(standings.first.wins, 1);
  });

  test('unscored matches are ignored', () {
    const players = [
      Player(id: 'a', name: 'Ana'),
      Player(id: 'b', name: 'Ben'),
      Player(id: 'c', name: 'Cal'),
      Player(id: 'd', name: 'Dee'),
    ];
    final rounds = [
      const GameRound(
        roundNum: 1,
        matches: [
          GameMatch(
            courtIndex: 1,
            teamA: ['a', 'b'],
            teamB: ['c', 'd'],
            firstServer: 'a',
          ),
        ],
        bench: [],
      ),
    ];
    final standings = StandingsCalculator.compute(players, rounds);
    expect(standings.every((s) => s.gamesPlayed == 0), isTrue);
  });
}
