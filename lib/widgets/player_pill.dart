import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A check-in pill used on the Launchpad roster grid. Active (checked-in)
/// players render with a high-contrast filled style; muted pills represent
/// known players who have not checked in for this session.
class PlayerPill extends StatelessWidget {
  final String name;
  final bool active;
  final int? byes;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const PlayerPill({
    super.key,
    required this.name,
    required this.active,
    this.byes,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: onTap,
        onLongPress: onLongPress,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            color: active ? AppColors.court : Colors.white,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: active ? AppColors.courtDark : Colors.grey.shade300,
              width: active ? 2.5 : 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                active ? Icons.check_circle : Icons.circle_outlined,
                size: 18,
                color: active ? Colors.white : Colors.grey,
              ),
              const SizedBox(width: 8),
              Text(
                name,
                style: TextStyle(
                  color: active ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              if (byes != null && byes! > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: active ? Colors.white24 : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${byes!} bye${byes! == 1 ? '' : 's'}',
                    style: TextStyle(
                      fontSize: 11,
                      color: active ? Colors.white : Colors.black54,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
