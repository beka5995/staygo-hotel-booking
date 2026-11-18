import 'package:flutter/material.dart';

class AppTheme {
  static const accent = Color(0xFFE25448);
  static ThemeData get light => _create(Brightness.light);
  static ThemeData get dark => _create(Brightness.dark);
  static ThemeData _create(Brightness brightness) {
    final colors = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: brightness,
    );
    final dark = brightness == Brightness.dark;
    final background = dark ? const Color(0xFF141518) : const Color(0xFFFAFAF9);
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colors,
      scaffoldBackgroundColor: background,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: colors.onSurface,
        scrolledUnderElevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surfaceContainerLow,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 13,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      cardTheme: CardThemeData(color: colors.surfaceContainerLow, elevation: 0),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colors.surfaceContainer,
        selectedItemColor: colors.primary,
        unselectedItemColor: colors.onSurfaceVariant,
      ),
    );
  }
}
