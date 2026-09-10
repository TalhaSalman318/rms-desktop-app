import 'package:flutter/material.dart';

abstract final class AppTheme {
  static const background = Color(0xFF090909);
  static const surface = Color(0xFF171312);
  static const surfaceRaised = Color(0xFF28201B);
  static const accent = Color(0xFFF04419);
  static const flameOrange = Color(0xFFFF7A00);
  static const flameYellow = Color(0xFFFFC928);
  static const cream = Color(0xFFFFF2D4);
  static const textPrimary = Color(0xFFFFF7E8);
  static const textSecondary = Color(0xFFC7B8A5);
  static const border = Color(0xFF4B3022);

  static const appGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF090909), Color(0xFF21110B), Color(0xFF0D0B0A)],
  );

  static const flameGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accent, flameOrange, flameYellow],
  );

  static ThemeData dark() {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        primary: accent,
        onPrimary: Colors.white,
        secondary: flameOrange,
        surface: surface,
        onSurface: textPrimary,
        error: Color(0xFFFF8A65),
      ),
      useMaterial3: true,
      fontFamily: 'Segoe UI',
      cardTheme: const CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          side: BorderSide(color: border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        hintStyle: const TextStyle(color: textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: accent, width: 1.5),
        ),
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          color: textPrimary,
          fontSize: 28,
          fontWeight: FontWeight.w700,
        ),
        titleLarge: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        bodyMedium: TextStyle(color: textSecondary, fontSize: 14),
      ),
      dividerTheme: const DividerThemeData(color: border),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: flameOrange,
      ),
    );
  }
}
