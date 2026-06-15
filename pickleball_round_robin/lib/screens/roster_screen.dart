import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../state/app_cubit.dart';
import '../theme/app_theme.dart';
import '../widgets/player_pill.dart';
import 'history_screen.dart';
import 'settings_screen.dart';

/// Screen 1 — The Launchpad. Roster check-in plus the sticky start control.
class RosterScreen extends StatefulWidget {
  const RosterScreen({super.key});

  @override
  State<RosterScreen> createState() => _RosterScreenState();
}

class _RosterScreenState extends State<RosterScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _add() {
    final text = _controller.text;
    if (text.trim().isEmpty) return;
    context.read<AppCubit>().addOrCheckInPlayer(text);
    _controller.clear();
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🥒 Round Robin'),
        actions: [
          IconButton(
            tooltip: 'Session history',
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const HistoryScreen()),
            ),
          ),
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _QuickAddBar(
            controller: _controller,
            focusNode: _focusNode,
            onSubmit: _add,
          ),
          Expanded(
            child: BlocBuilder<AppCubit, AppData>(
              builder: (context, state) {
                final players = [...state.masterRoster]
                  ..sort((a, b) {
                    if (a.isActive != b.isActive) return a.isActive ? -1 : 1;
                    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
                  });
                if (players.isEmpty) {
                  return const _EmptyRoster();
                }
                final checkedIn =
                    players.where((p) => p.isActive).length;
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          '$checkedIn checked in · tap to toggle · long-press to remove',
                          style: TextStyle(
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          for (final p in players)
                            PlayerPill(
                              name: p.name,
                              active: p.isActive,
                              onTap: () =>
                                  context.read<AppCubit>().toggleCheckIn(p.id),
                              onLongPress: () =>
                                  _confirmDelete(context, p.id, p.name),
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const _StickyControlPanel(),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, String id, String name) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Remove $name?'),
        content: const Text(
            'This deletes the player from the master database permanently.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.teamB),
            onPressed: () {
              context.read<AppCubit>().deletePlayerFromRoster(id);
              Navigator.pop(ctx);
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}

class _QuickAddBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSubmit;

  const _QuickAddBar({
    required this.controller,
    required this.focusNode,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.courtDark,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              autofocus: true,
              textInputAction: TextInputAction.done,
              textCapitalization: TextCapitalization.words,
              onSubmitted: (_) => onSubmit(),
              decoration: InputDecoration(
                hintText: 'Add a player…',
                filled: true,
                fillColor: Colors.white,
                prefixIcon: const Icon(Icons.person_add_alt_1),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: onSubmit,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.ball,
                foregroundColor: Colors.black87,
                minimumSize: const Size(56, 52),
                padding: const EdgeInsets.symmetric(horizontal: 18),
              ),
              child: const Icon(Icons.add, size: 28),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyRoster extends StatelessWidget {
  const _EmptyRoster();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🏓', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text(
              'Add players up top to check them in.\nYou can be on a court in under 30 seconds.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _StickyControlPanel extends StatelessWidget {
  const _StickyControlPanel();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppData>(
      builder: (context, state) {
        final cubit = context.read<AppCubit>();
        final checkedIn = state.masterRoster.where((p) => p.isActive).length;
        final canStart = checkedIn >= 4;
        return Material(
          elevation: 12,
          color: Colors.white,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.sports_tennis, color: AppColors.court),
                      const SizedBox(width: 8),
                      const Text('Courts',
                          style: TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 16)),
                      const Spacer(),
                      _Stepper(
                        value: state.pendingCourts,
                        min: 1,
                        max: 12,
                        onChanged: cubit.setPendingCourts,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: canStart
                        ? () {
                            final ok = cubit.startRoundRobin();
                            if (!ok) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Need at least 4 checked-in players.')),
                              );
                            }
                          }
                        : null,
                    icon: const Icon(Icons.play_arrow_rounded, size: 28),
                    label: Text(canStart
                        ? 'START ROUND ROBIN'
                        : 'CHECK IN ${4 - checkedIn} MORE'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Stepper extends StatelessWidget {
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  const _Stepper({
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: value > min ? () => onChanged(value - 1) : null,
            icon: const Icon(Icons.remove_circle, size: 30),
            color: AppColors.court,
          ),
          SizedBox(
            width: 32,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style:
                  const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
          ),
          IconButton(
            onPressed: value < max ? () => onChanged(value + 1) : null,
            icon: const Icon(Icons.add_circle, size: 30),
            color: AppColors.court,
          ),
        ],
      ),
    );
  }
}
