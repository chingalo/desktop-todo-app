import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/database.dart';
import 'state/auth_controller.dart';
import 'state/session_store.dart';
import 'ui/app_theme.dart';
import 'ui/auth/auth_screen.dart';
import 'ui/home/home_shell.dart';

/// Bootstraps providers + [ProgramPilotApp] for production ([main]) and for
/// `integration_test` (pump the returned [root] with a test binding).
///
/// Pass [sessionStore] to avoid platform secure storage (e.g. [InMemorySessionStore]
/// for integration tests on macOS without extra Keychain entitlements).
Future<ProgramPilotHarness> assembleProgramPilotHarness({
  SessionStore? sessionStore,
}) async {
  final database = AppDatabase();
  final auth = AuthController(
    database: database,
    sessionStore: sessionStore ?? SecureSessionStore(),
  );
  await auth.loadSession();
  final root = MultiProvider(
    providers: [
      Provider<AppDatabase>.value(value: database),
      ChangeNotifierProvider<AuthController>.value(value: auth),
    ],
    child: const ProgramPilotApp(),
  );
  return ProgramPilotHarness(root: root, database: database, auth: auth);
}

/// Handle to tear down Drift after an integration test run.
class ProgramPilotHarness {
  const ProgramPilotHarness({
    required this.root,
    required this.database,
    required this.auth,
  });

  final Widget root;
  final AppDatabase database;
  final AuthController auth;

  Future<void> dispose() => database.close();
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final harness = await assembleProgramPilotHarness();
  runApp(harness.root);
}

class ProgramPilotApp extends StatelessWidget {
  const ProgramPilotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ProgramPilot',
      debugShowCheckedModeBanner: false,
      theme: buildProgramPilotTheme(),
      darkTheme: buildProgramPilotTheme(dark: true),
      themeMode: ThemeMode.system,
      home: const _AuthGate(),
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    final signedIn = context.watch<AuthController>().isSignedIn;
    return signedIn ? const HomeShell() : const AuthScreen();
  }
}
