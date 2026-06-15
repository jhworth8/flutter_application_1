import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/models.dart';
import '../services/share_service.dart';
import '../state/app_cubit.dart';
import '../theme/app_theme.dart';

/// Screen 3 — Live Standings & Tournament Analytics.
class StandingsScreen extends StatelessWidget {
  const StandingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final shareKey = GlobalKey();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Standings'),
        actions: [
          IconButton(
            tooltip: 'Share standings',
            icon: const Icon(Icons.ios_share),
            onPressed: () => ShareService.shareBoundary(
              shareKey,
              text: 'Current standings 🥒',
              fileName: 'standings.png',
            ),
          ),
        ],
      ),
      body: BlocBuilder<AppCubit, AppData>(
        builder: (context, state) {
          final standings = context.read<AppCubit>().currentStandings();
          if (standings.isEmpty) {
            return const Center(child: Text('No matches played yet.'));
          }
          return SingleChildScrollView(
            child: RepaintBoundary(
              key: shareKey,
              child: Container(
                color: Colors.white,
                child: StandingsTable(standings: standings),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Reusable standings table, also used in the historical session vault.
class StandingsTable extends StatelessWidget {
  final List<Standing> standings;
  const StandingsTable({super.key, required this.standings});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: AppColors.courtDark,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: const Row(
            children: [
              SizedBox(
                  width: 34,
                  child: Text('#',
                      style: _headStyle, textAlign: TextAlign.center)),
              Expanded(child: Text('Player', style: _headStyle)),
              _HeadCell('W'),
              _HeadCell('L'),
              _HeadCell('+/–', width: 56),
            ],
          ),
        ),
        for (var i = 0; i < standings.length; i++)
          _StandingRow(rank: i + 1, standing: standings[i]),
      ],
    );
  }
}

class _StandingRow extends StatelessWidget {
  final int rank;
  final Standing standing;
  const _StandingRow({required this.rank, required this.standing});

  @override
  Widget build(BuildContext context) {
    final medal = switch (rank) {
      1 => '🥇',
      2 => '🥈',
      3 => '🥉',
      _ => null,
    };
    final diff = standing.pointDifferential;
    final diffStr = diff > 0 ? '+$diff' : '$diff';
    return Container(
      decoration: BoxDecoration(
        color: rank.isEven ? AppColors.surface : Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          SizedBox(
            width: 34,
            child: Text(
              medal ?? '$rank',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
          ),
          Expanded(
            child: Text(
              standing.name,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
          ),
          _DataCell('${standing.wins}'),
          _DataCell('${standing.losses}'),
          _DataCell(
            diffStr,
            width: 56,
            color: diff > 0
                ? AppColors.win
                : (diff < 0 ? AppColors.teamB : Colors.black54),
          ),
        ],
      ),
    );
  }
}

const _headStyle = TextStyle(
  color: Colors.white,
  fontWeight: FontWeight.w800,
  fontSize: 14,
);

class _HeadCell extends StatelessWidget {
  final String label;
  final double width;
  const _HeadCell(this.label, {this.width = 40});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Text(label, style: _headStyle, textAlign: TextAlign.center),
    );
  }
}

class _DataCell extends StatelessWidget {
  final String value;
  final double width;
  final Color? color;
  const _DataCell(this.value, {this.width = 40, this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Text(
        value,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: color ?? Colors.black87,
        ),
      ),
    );
  }
}
