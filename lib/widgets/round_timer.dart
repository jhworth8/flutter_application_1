import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A simple per-round countdown timer for timed games. Start / pause / reset
/// are controlled inline; resets whenever [durationSeconds] changes (e.g. a new
/// round begins or settings change).
class RoundTimer extends StatefulWidget {
  final int durationSeconds;

  const RoundTimer({super.key, required this.durationSeconds});

  @override
  State<RoundTimer> createState() => _RoundTimerState();
}

class _RoundTimerState extends State<RoundTimer> {
  late int _remaining;
  Timer? _timer;
  bool _running = false;

  @override
  void initState() {
    super.initState();
    _remaining = widget.durationSeconds;
  }

  @override
  void didUpdateWidget(RoundTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.durationSeconds != widget.durationSeconds) {
      _reset();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggle() {
    if (_running) {
      _timer?.cancel();
      setState(() => _running = false);
    } else {
      setState(() => _running = true);
      _timer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (_remaining <= 0) {
          t.cancel();
          setState(() => _running = false);
          return;
        }
        setState(() => _remaining--);
      });
    }
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _remaining = widget.durationSeconds;
      _running = false;
    });
  }

  String get _formatted {
    final m = (_remaining ~/ 60).toString().padLeft(2, '0');
    final s = (_remaining % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final expired = _remaining <= 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: expired ? AppColors.teamB : AppColors.courtDark,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.timer_outlined, color: Colors.white),
          const SizedBox(width: 10),
          Text(
            expired ? "TIME'S UP" : _formatted,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(width: 16),
          IconButton(
            onPressed: _toggle,
            icon: Icon(_running ? Icons.pause_circle : Icons.play_circle,
                color: Colors.white, size: 30),
          ),
          IconButton(
            onPressed: _reset,
            icon: const Icon(Icons.replay_circle_filled,
                color: Colors.white70, size: 26),
          ),
        ],
      ),
    );
  }
}
