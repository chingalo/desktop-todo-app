import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:dhis_todo/main.dart' as app;
import 'package:dhis_todo/state/in_memory_session_store.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  /// Full desktop binary + Drift + Provider; session avoids Keychain (-34018).
  testWidgets('signed-out shell shows auth UI', (tester) async {
    final harness = await app.assembleProgramPilotHarness(
      sessionStore: InMemorySessionStore(),
    );
    try {
      await tester.pumpWidget(harness.root);
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.textContaining('ProgramPilot'), findsWidgets);
      expect(find.text('Sign in'), findsWidgets);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await harness.dispose();
      await tester.pump(const Duration(milliseconds: 200));
    }
  });

  /// Same harness as production; auth completes via [AuthController] then UI updates.
  testWidgets('after sign up, home shell shows navigation rail', (tester) async {
    final harness = await app.assembleProgramPilotHarness(
      sessionStore: InMemorySessionStore(),
    );
    try {
      await tester.pumpWidget(harness.root);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(
        await harness.auth.signUp('integration@example.dev', 'password12'),
        isNull,
      );
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.text('Todos'), findsOneWidget);
      expect(find.byType(NavigationRail), findsOneWidget);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await harness.dispose();
      await tester.pump(const Duration(milliseconds: 200));
    }
  });
}
