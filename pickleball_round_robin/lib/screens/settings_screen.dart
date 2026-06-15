import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/models.dart';
import '../state/app_cubit.dart';
import '../theme/app_theme.dart';

/// Screen 4 — Global Settings & Roster Management.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: BlocBuilder<AppCubit, AppData>(
        builder: (context, state) {
          final cubit = context.read<AppCubit>();
          // While a session is live, edit its rules; otherwise edit defaults.
          final rules = state.session?.rules ?? state.defaultRules;

          void apply(Rules next) {
            cubit.updateDefaultRules(next);
            if (state.hasSession) cubit.updateSessionRules(next);
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const _SectionLabel('Default game parameters'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Scoring mode',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      SegmentedButton<ScoringMode>(
                        segments: const [
                          ButtonSegment(
                              value: ScoringMode.rally, label: Text('Rally')),
                          ButtonSegment(
                              value: ScoringMode.sideOut,
                              label: Text('Side-Out')),
                        ],
                        selected: {rules.scoringMode},
                        onSelectionChanged: (s) =>
                            apply(rules.copyWith(scoringMode: s.first)),
                      ),
                      const Divider(height: 28),
                      const Text('Target score',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      SegmentedButton<int>(
                        segments: const [
                          ButtonSegment(value: 11, label: Text('11')),
                          ButtonSegment(value: 15, label: Text('15')),
                          ButtonSegment(value: 21, label: Text('21')),
                        ],
                        selected: {_nearestTarget(rules.targetScore)},
                        onSelectionChanged: (s) =>
                            apply(rules.copyWith(targetScore: s.first)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const _SectionLabel('Timer'),
              Card(
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Use round timer'),
                      value: rules.useTimer,
                      onChanged: (v) => apply(rules.copyWith(useTimer: v)),
                    ),
                    if (rules.useTimer)
                      ListTile(
                        title: const Text('Round length'),
                        trailing: DropdownButton<int>(
                          value: rules.timerDurationSeconds,
                          items: const [
                            DropdownMenuItem(value: 300, child: Text('5 min')),
                            DropdownMenuItem(value: 480, child: Text('8 min')),
                            DropdownMenuItem(value: 600, child: Text('10 min')),
                            DropdownMenuItem(value: 720, child: Text('12 min')),
                            DropdownMenuItem(value: 900, child: Text('15 min')),
                          ],
                          onChanged: (v) => apply(
                              rules.copyWith(timerDurationSeconds: v ?? 720)),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const _SectionLabel('Bulk roster import'),
              const _BulkImportCard(),
              if (state.hasSession) ...[
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.teamB),
                  onPressed: () => _confirmDiscard(context),
                  icon: const Icon(Icons.delete_forever),
                  label: const Text('Discard active session'),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  static int _nearestTarget(int v) {
    if (v <= 11) return 11;
    if (v <= 15) return 15;
    return 21;
  }

  void _confirmDiscard(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Discard session?'),
        content: const Text(
            'The current tournament will be deleted without being archived.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.teamB),
            onPressed: () {
              context.read<AppCubit>().discardSession();
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('Discard'),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          color: Colors.grey.shade600,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _BulkImportCard extends StatefulWidget {
  const _BulkImportCard();

  @override
  State<_BulkImportCard> createState() => _BulkImportCardState();
}

class _BulkImportCardState extends State<_BulkImportCard> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _controller,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Jesse, Emily, Lance, Claire…',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: () {
                final text = _controller.text;
                if (text.trim().isEmpty) return;
                context.read<AppCubit>().addPlayersBulk(text);
                _controller.clear();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Players added & checked in.')),
                );
              },
              icon: const Icon(Icons.playlist_add),
              label: const Text('Add all'),
            ),
          ],
        ),
      ),
    );
  }
}
