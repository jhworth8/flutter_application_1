// Smoke test: the app boots into the Launchpad once persisted state loads.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pickleball_round_robin/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Launchpad renders after state loads', (tester) async {
    await tester.pumpWidget(const RoundRobinApp());
    await tester.pumpAndSettle();

    expect(find.textContaining('Round Robin'), findsWidgets);
    // Empty roster prompts the organizer to check players in before starting.
    expect(find.textContaining('CHECK IN'), findsOneWidget);
  });
}
