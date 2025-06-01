import 'package:flutter/material.dart';

class AppTheme {
  // Dark theme colors
  static const _darkPrimaryColor = Color(0xFF00A3FF);
  static const _darkSecondaryColor = Color(0xFF22C55E);
  static const _darkSurfaceColor = Color(0xFF1A1A1A);
  static const _darkErrorColor = Color(0xFFEF4444);
  static const _darkOnPrimaryColor = Colors.white;
  static const _darkOnSecondaryColor = Colors.white;
  static const _darkOnSurfaceColor = Colors.white;
  static const _darkOnErrorColor = Colors.white;

  // Light theme colors
  static const _lightPrimaryColor =
      Color(0xFF0284C7); // Slightly darker blue for better contrast
  static const _lightSecondaryColor = Color(0xFF059669); // Adjusted green
  static const _lightSurfaceColor = Color(0xFFFAFAFA); // Light surface
  static const _lightErrorColor = Color(0xFFDC2626); // Adjusted red
  static const _lightOnPrimaryColor = Colors.white;
  static const _lightOnSecondaryColor = Colors.white;
  static const _lightOnSurfaceColor =
      Color(0xFF1A1A1A); // Dark text for light mode
  static const _lightOnErrorColor = Colors.white;

  // Common text styles
  static const _defaultTextTheme = TextTheme(
    displayLarge: TextStyle(
      fontSize: 57,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.25,
    ),
    displayMedium: TextStyle(
      fontSize: 45,
      fontWeight: FontWeight.w600,
    ),
    displaySmall: TextStyle(
      fontSize: 36,
      fontWeight: FontWeight.w600,
    ),
    headlineLarge: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.w600,
    ),
    headlineMedium: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w600,
    ),
    headlineSmall: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w600,
    ),
    titleLarge: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.15,
    ),
    bodyLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.15,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.25,
    ),
  );

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme(
        brightness: Brightness.dark,
        primary: _darkPrimaryColor,
        onPrimary: _darkOnPrimaryColor,
        secondary: _darkSecondaryColor,
        onSecondary: _darkOnSecondaryColor,
        error: _darkErrorColor,
        onError: _darkOnErrorColor,
        surface: _darkSurfaceColor,
        onSurface: _darkOnSurfaceColor,
      ),
      textTheme: _defaultTextTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: _darkSurfaceColor,
        foregroundColor: _darkOnSurfaceColor,
        shadowColor: _darkPrimaryColor.withValues(alpha: 0.1),
      ),
      cardTheme: CardThemeData(
        color: _darkSurfaceColor,
        elevation: 2,
        shadowColor: _darkPrimaryColor.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _darkPrimaryColor,
          foregroundColor: _darkOnPrimaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 16,
          ),
          elevation: 2,
          shadowColor: _darkPrimaryColor.withValues(alpha: 0.3),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _darkSurfaceColor.withValues(alpha: 0.8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: _darkOnSurfaceColor.withValues(alpha: 0.12),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: _darkPrimaryColor,
            width: 2,
          ),
        ),
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme(
        brightness: Brightness.light,
        primary: _lightPrimaryColor,
        onPrimary: _lightOnPrimaryColor,
        secondary: _lightSecondaryColor,
        onSecondary: _lightOnSecondaryColor,
        error: _lightErrorColor,
        onError: _lightOnErrorColor,
        surface: _lightSurfaceColor,
        onSurface: _lightOnSurfaceColor,
      ),
      textTheme: _defaultTextTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: _lightSurfaceColor,
        foregroundColor: _lightOnSurfaceColor,
        shadowColor: _lightPrimaryColor.withValues(alpha: 0.1),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2,
        shadowColor: _lightPrimaryColor.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _lightPrimaryColor,
          foregroundColor: _lightOnPrimaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 16,
          ),
          elevation: 2,
          shadowColor: _lightPrimaryColor.withValues(alpha: 0.3),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: _lightOnSurfaceColor.withValues(alpha: 0.12),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: _lightPrimaryColor,
            width: 2,
          ),
        ),
      ),
    );
  }
}
