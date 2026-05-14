import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/database.dart';
import 'state/auth_controller.dart';
import 'ui/app_theme.dart';
import 'ui/auth/auth_screen.dart';
import 'ui/home/home_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final database = AppDatabase();
  final auth = AuthController(database: database);
  await auth.loadSession();
  runApp(
    MultiProvider(
      providers: [
        Provider<AppDatabase>.value(value: database),
        ChangeNotifierProvider<AuthController>.value(value: auth),
      ],
      child: const ProgramPilotApp(),
    ),
  );
}

class ProgramPilotApp extends StatelessWidget {
  const ProgramPilotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ProgramPilot',
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
