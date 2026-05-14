import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:dhis_todo/data/database.dart';
import 'package:dhis_todo/main.dart';
import 'package:dhis_todo/state/auth_controller.dart';
import 'package:drift/native.dart';

import 'support/in_memory_session_store.dart';

/// Drift query streams schedule timers; unmount and close DB before the test ends.
Future<void> _tearDownApp(WidgetTester tester, AppDatabase database) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
  await database.close();
  await tester.pump(const Duration(milliseconds: 200));
}

void main() {
  testWidgets('ProgramPilot shows sign-in when logged out', (tester) async {
    final database = AppDatabase(NativeDatabase.memory());
    final auth = AuthController(
      database: database,
      sessionStore: InMemorySessionStore(),
    );
    await auth.loadSession();

    try {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<AppDatabase>.value(value: database),
            ChangeNotifierProvider<AuthController>.value(value: auth),
          ],
          child: const ProgramPilotApp(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.textContaining('ProgramPilot'), findsWidgets);
      expect(find.text('Sign in'), findsWidgets);
    } finally {
      await _tearDownApp(tester, database);
    }
  });
}
