import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// High-contrast footer strip listing players resting during the active round.
class BenchShelf extends StatelessWidget {
  final List<String> names;

  const BenchShelf({super.key, required this.names});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.bench,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.event_seat, color: Colors.white70, size: 18),
              SizedBox(width: 6),
              Text(
                'ON THE BENCH',
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (names.isEmpty)
            const Text(
              'Everyone is playing this round 🎉',
              style: TextStyle(color: Colors.white, fontSize: 15),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final name in names)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
