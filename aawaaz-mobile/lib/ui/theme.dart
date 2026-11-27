import 'package:flutter/material.dart';

/// App theme tuned for the factory floor: larger text, tall tap targets, strong
/// contrast, consistent outlined inputs.
ThemeData aawaazTheme(Brightness brightness) {
  final scheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF00695C),
    brightness: brightness,
  );
  final base = ThemeData(colorScheme: scheme, useMaterial3: true);

  return base.copyWith(
    visualDensity: VisualDensity.comfortable,
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(56),
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.primary,
      foregroundColor: scheme.onPrimary,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: scheme.onPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
    cardTheme: const CardThemeData(
      clipBehavior: Clip.antiAlias,
      elevation: 1,
    ),
  );
}
