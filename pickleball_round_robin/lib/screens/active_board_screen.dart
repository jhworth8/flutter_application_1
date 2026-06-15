import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../services/share_service.dart';
import '../state/app_cubit.dart';
import '../theme/app_theme.dart';
import '../widgets/bench_shelf.dart';
import '../widgets/court_card.dart';
import '../widgets/round_timer.dart';
import 'standings_screen.dart';

/// Boundary key for rasterizing the current matchups into a shareable image.
final GlobalKey _boardShareKey = GlobalKey();

/// Screen 2 — The Active Board. Bench-legible live match center.
class ActiveBoardScreen extends StatelessWidget {
  const ActiveBoardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppData>(
      builder: (context, state) {
        final session = state.session;
        if (session == null) return const SizedBox.shrink();
        final round = session.currentRound;
        final cubit = context.read<AppCubit>();

        return Scaffold(
          appBar: AppBar(
            title: Text('Round ${round?.roundNum ?? session.currentRoundIndex}'),
            actions: [
              IconButton(
                tooltip: 'Standings',
                icon: const Icon(Icons.leaderboard),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const StandingsScreen()),
                ),
              ),
              IconButton(
                tooltip: 'Manage players & courts',
                icon: const Icon(Icons.group),
                onPressed: () => _openManageSheet(context),
              ),
              PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'share') {
                    ShareService.shareBoundary(
                      _boardShareKey,
                      text: 'Round ${round?.roundNum} matchups 🥒',
                      fileName: 'matchups.png',
                    );
                  } else if (v == 'regen') {
                    cubit.regenerateCurrentRound();
                  } else if (v == 'end') {
                    _confirmEnd(context);
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                      value: 'share',
                      child: ListTile(
                          leading: Icon(Icons.ios_share),
                          title: Text('Share matchups'))),
                  PopupMenuItem(
                      value: 'regen',
                      child: ListTile(
                          leading: Icon(Icons.casino),
                          title: Text('Re-roll this round'))),
                  PopupMenuItem(
                      value: 'end',
                      child: ListTile(
                          leading: Icon(Icons.flag),
                          title: Text('End tournament'))),
                ],
              ),
            ],
          ),
          body: Column(
            children: [
              if (session.rules.useTimer)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child:
                      RoundTimer(durationSeconds: session.rules.timerDurationSeconds),
                ),
              Expanded(
                child: RepaintBoundary(
                  key: _boardShareKey,
                  child: Container(
                    color: AppColors.surface,
                    child: round == null || round.matches.isEmpty
                        ? const _NotEnoughPlayers()
                        : ListView(
                            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                            children: [
                              for (final m in round.matches)
                                Padding(
                                  padding:
                                      const EdgeInsets.only(bottom: 12),
                                  child: CourtCard(
                                    match: m,
                                    nameOf: session.nameOf,
                                    onPickWinner: (side) =>
                                        cubit.setMatchWinner(m.courtIndex, side),
                                    onSetScore: (a, b) => cubit.setMatchScore(
                                        m.courtIndex,
                                        scoreA: a,
                                        scoreB: b),
                                  ),
                                ),
                            ],
                          ),
                  ),
                ),
              ),
              BenchShelf(
                names: (round?.bench ?? const [])
                    .map(session.nameOf)
                    .toList(),
              ),
              _NextRoundBar(canAdvance: cubit.canAdvance),
            ],
          ),
        );
      },
    );
  }

  void _confirmEnd(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('End tournament?'),
        content: const Text(
            'Final standings will be saved to the session archive and the board will reset.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Keep playing')),
          FilledButton(
            onPressed: () {
              context.read<AppCubit>().endSession();
              Navigator.pop(ctx);
            },
            child: const Text('End & save'),
          ),
        ],
      ),
    );
  }

  void _openManageSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _ManageSheet(),
    );
  }
}

class _NextRoundBar extends StatelessWidget {
  final bool canAdvance;
  const _NextRoundBar({required this.canAdvance});

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 12,
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: FilledButton.icon(
            onPressed: canAdvance
                ? () => context.read<AppCubit>().nextRound()
                : null,
            icon: const Icon(Icons.skip_next, size: 28),
            label: Text(canAdvance
                ? 'NEXT ROUND'
                : 'PICK EVERY WINNER TO CONTINUE'),
          ),
        ),
      ),
    );
  }
}

class _NotEnoughPlayers extends StatelessWidget {
  const _NotEnoughPlayers();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Text(
          'Not enough active players to fill a court.\nAdd players or check someone back in.',
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

/// "Life happens" overlay — late arrivals, early departures, court changes.
class _ManageSheet extends StatefulWidget {
  const _ManageSheet();

  @override
  State<_ManageSheet> createState() => _ManageSheetState();
}

class _ManageSheetState extends State<_ManageSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: BlocBuilder<AppCubit, AppData>(
        builder: (context, state) {
          final session = state.session;
          if (session == null) return const SizedBox.shrink();
          final cubit = context.read<AppCubit>();
          final players = [...session.players]
            ..sort((a, b) =>
                a.name.toLowerCase().compareTo(b.name.toLowerCase()));

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Manage session',
                  style:
                      TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      textCapitalization: TextCapitalization.words,
                      onSubmitted: (_) => _addLate(cubit),
                      decoration: InputDecoration(
                        hintText: 'Late arrival name…',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () => _addLate(cubit),
                    child: const Text('Add'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.sports_tennis, color: AppColors.court),
                  const SizedBox(width: 8),
                  const Text('Courts available',
                      style: TextStyle(fontWeight: FontWeight.w800)),
                  const Spacer(),
                  IconButton(
                    onPressed: session.courtsAvailable > 1
                        ? () =>
                            cubit.setSessionCourts(session.courtsAvailable - 1)
                        : null,
                    icon: const Icon(Icons.remove_circle, size: 28),
                    color: AppColors.court,
                  ),
                  Text('${session.courtsAvailable}',
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w900)),
                  IconButton(
                    onPressed: () =>
                        cubit.setSessionCourts(session.courtsAvailable + 1),
                    icon: const Icon(Icons.add_circle, size: 28),
                    color: AppColors.court,
                  ),
                ],
              ),
              const Divider(height: 24),
              Text('Players (${session.activePlayers.length} active)',
                  style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final p in players)
                      SwitchListTile(
                        dense: true,
                        title: Text(p.name,
                            style:
                                const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text('${p.byes} bye(s)'),
                        value: p.isActive,
                        onChanged: (_) =>
                            cubit.togglePlayerActiveInSession(p.id),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () {
                  cubit.regenerateCurrentRound();
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.casino),
                label: const Text('Re-roll current round with these changes'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _addLate(AppCubit cubit) {
    if (_controller.text.trim().isEmpty) return;
    cubit.addLatePlayer(_controller.text);
    _controller.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text(
              'Added — re-roll the round to put them on a court right away.')),
    );
  }
}
