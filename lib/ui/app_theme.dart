import 'package:flutter/material.dart';

ThemeData buildProgramPilotTheme({bool dark = false}) {
  const seed = Color(0xFF0D9488); // teal-600
  final scheme = ColorScheme.fromSeed(
    seedColor: seed,
    brightness: dark ? Brightness.dark : Brightness.light,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    visualDensity: VisualDensity.adaptivePlatformDensity,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: scheme.surfaceContainerLow,
      indicatorColor: scheme.secondaryContainer,
    ),
  );
}
