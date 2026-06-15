import 'package:flutter/material.dart';

import '../models/models.dart';
import '../theme/app_theme.dart';

/// A top-down 2D representation of a single pickleball court. Each half (Team A
/// / Team B) is a large tap target that records the match winner. A star marks
/// the algorithmically assigned first server.
class CourtCard extends StatelessWidget {
  final GameMatch match;
  final String Function(String id) nameOf;
  final void Function(TeamSide side) onPickWinner;
  final void Function(int scoreA, int scoreB) onSetScore;

  const CourtCard({
    super.key,
    required this.match,
    required this.nameOf,
    required this.onPickWinner,
    required this.onSetScore,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: AppColors.courtDark,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'COURT ${match.courtIndex}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    letterSpacing: 1.2,
                  ),
                ),
                if (match.isComplete)
                  const Icon(Icons.check_circle, color: AppColors.ball, size: 20)
                else
                  const Text(
                    'TAP WINNER',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
              ],
            ),
          ),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _TeamHalf(
                    side: TeamSide.a,
                    color: AppColors.teamA,
                    players: match.teamA,
                    score: match.scoreA,
                    firstServer: match.firstServer,
                    isWinner: match.winner == TeamSide.a,
                    decided: match.isComplete,
                    nameOf: nameOf,
                    onTap: () => onPickWinner(TeamSide.a),
                  ),
                ),
                const _NetDivider(),
                Expanded(
                  child: _TeamHalf(
                    side: TeamSide.b,
                    color: AppColors.teamB,
                    players: match.teamB,
                    score: match.scoreB,
                    firstServer: match.firstServer,
                    isWinner: match.winner == TeamSide.b,
                    decided: match.isComplete,
                    nameOf: nameOf,
                    onTap: () => onPickWinner(TeamSide.b),
                  ),
                ),
              ],
            ),
          ),
          // Optional precise score entry for accurate point differential.
          Container(
            color: Colors.grey.shade100,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _ScoreStepper(
                  label: 'A',
                  color: AppColors.teamA,
                  value: match.scoreA,
                  onChanged: (v) => onSetScore(v, match.scoreB),
                ),
                const SizedBox(width: 24),
                _ScoreStepper(
                  label: 'B',
                  color: AppColors.teamB,
                  value: match.scoreB,
                  onChanged: (v) => onSetScore(match.scoreA, v),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TeamHalf extends StatelessWidget {
  final TeamSide side;
  final Color color;
  final List<String> players;
  final int score;
  final String firstServer;
  final bool isWinner;
  final bool decided;
  final String Function(String id) nameOf;
  final VoidCallback onTap;

  const _TeamHalf({
    required this.side,
    required this.color,
    required this.players,
    required this.score,
    required this.firstServer,
    required this.isWinner,
    required this.decided,
    required this.nameOf,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final highlight = isWinner;
    final dimmed = decided && !isWinner;
    return InkWell(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        constraints: const BoxConstraints(minHeight: 120),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        color: highlight
            ? AppColors.win.withOpacity(0.18)
            : (dimmed ? Colors.grey.shade200 : Colors.white),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 34,
              height: 6,
              decoration: BoxDecoration(
                color: dimmed ? Colors.grey : color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 10),
            for (final id in players)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (id == firstServer)
                      const Padding(
                        padding: EdgeInsets.only(right: 4),
                        child: Icon(Icons.star,
                            size: 16, color: Color(0xFFEAB308)),
                      ),
                    Flexible(
                      child: Text(
                        nameOf(id),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: dimmed ? Colors.grey.shade600 : Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            if (highlight)
              const Text(
                'WINNER',
                style: TextStyle(
                  color: AppColors.win,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  letterSpacing: 1.0,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NetDivider extends StatelessWidget {
  const _NetDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 2,
      color: Colors.grey.shade400,
    );
  }
}

class _ScoreStepper extends StatelessWidget {
  final String label;
  final Color color;
  final int value;
  final ValueChanged<int> onChanged;

  const _ScoreStepper({
    required this.label,
    required this.color,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$label ',
            style: TextStyle(fontWeight: FontWeight.w800, color: color)),
        IconButton(
          visualDensity: VisualDensity.compact,
          onPressed: value > 0 ? () => onChanged(value - 1) : null,
          icon: const Icon(Icons.remove_circle_outline),
        ),
        SizedBox(
          width: 26,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          onPressed: () => onChanged(value + 1),
          icon: const Icon(Icons.add_circle_outline),
        ),
      ],
    );
  }
}
