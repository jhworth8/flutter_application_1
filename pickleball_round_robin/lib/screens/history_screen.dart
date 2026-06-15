import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../models/models.dart';
import '../state/app_cubit.dart';
import '../theme/app_theme.dart';
import 'standings_screen.dart';

/// Screen 5 — Historical Session Vault. Immutable archive of past round-robins.
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Session History')),
      body: BlocBuilder<AppCubit, AppData>(
        builder: (context, state) {
          if (state.archive.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'No completed tournaments yet.\nFinished sessions are archived here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w600),
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: state.archive.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final session = state.archive[i];
              return _ArchiveCard(session: session);
            },
          );
        },
      ),
    );
  }
}

class _ArchiveCard extends StatelessWidget {
  final ArchivedSession session;
  const _ArchiveCard({required this.session});

  @override
  Widget build(BuildContext context) {
    final date = DateTime.tryParse(session.date)?.toLocal();
    final dateStr =
        date != null ? DateFormat('EEE, MMM d · h:mm a').format(date) : session.date;
    final podium = session.podium;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => _ArchiveDetail(session: session)),
        ),
        onLongPress: () => _confirmDelete(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.emoji_events, color: AppColors.court),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(dateStr,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 16)),
                  ),
                  Text('${session.roundsPlayed} rounds',
                      style: TextStyle(color: Colors.grey.shade600)),
                ],
              ),
              const SizedBox(height: 12),
              for (var i = 0; i < podium.length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Text(['🥇', '🥈', '🥉'][i],
                          style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(podium[i].name,
                            style:
                                const TextStyle(fontWeight: FontWeight.w700)),
                      ),
                      Text(
                          '${podium[i].wins}W · ${podium[i].pointDifferential >= 0 ? '+' : ''}${podium[i].pointDifferential}',
                          style: TextStyle(color: Colors.grey.shade700)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete archived session?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.teamB),
            onPressed: () {
              context.read<AppCubit>().deleteArchivedSession(session.id);
              Navigator.pop(ctx);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

/// Read-only deep dive into a single archived tournament.
class _ArchiveDetail extends StatelessWidget {
  final ArchivedSession session;
  const _ArchiveDetail({required this.session});

  @override
  Widget build(BuildContext context) {
    final nameOf = {
      for (final s in session.standings) s.playerId: s.name,
    };
    return Scaffold(
      appBar: AppBar(title: const Text('Final Results')),
      body: ListView(
        children: [
          StandingsTable(standings: session.standings),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Text('ROUNDS',
                style: TextStyle(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8)),
          ),
          for (final round in session.rounds)
            _RoundSummary(round: round, nameOf: nameOf),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _RoundSummary extends StatelessWidget {
  final GameRound round;
  final Map<String, String> nameOf;
  const _RoundSummary({required this.round, required this.nameOf});

  String _names(List<String> ids) =>
      ids.map((id) => nameOf[id] ?? id).join(' & ');

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Round ${round.roundNum}',
                style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            for (final m in round.matches)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  'Court ${m.courtIndex}:  ${_names(m.teamA)}  ${m.scoreA}–${m.scoreB}  ${_names(m.teamB)}',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
