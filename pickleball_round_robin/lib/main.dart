import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'screens/active_board_screen.dart';
import 'screens/roster_screen.dart';
import 'state/app_cubit.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const RoundRobinApp());
}

class RoundRobinApp extends StatelessWidget {
  const RoundRobinApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AppCubit>(
      create: (_) => AppCubit()..init(),
      child: MaterialApp(
        title: 'Pickleball Round Robin',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const _HomeShell(),
      ),
    );
  }
}

/// Routes between the Launchpad and the Active Board based on whether a live
/// session exists, restoring straight into play after a crash/relaunch.
class _HomeShell extends StatelessWidget {
  const _HomeShell();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppData>(
      builder: (context, state) {
        if (!state.loaded) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: state.hasSession
              ? const ActiveBoardScreen(key: ValueKey('board'))
              : const RosterScreen(key: ValueKey('roster')),
        );
      },
    );
  }
}
