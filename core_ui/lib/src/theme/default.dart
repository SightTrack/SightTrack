import 'package:flutter/material.dart';

class AppTheme {
  // Updated colors for better visibility and modern look
  static const _primaryColor = Color(0xFF00A3FF); // Bright blue, more visible
  static const _secondaryColor = Color(0xFF22C55E); // Modern green
  static const _surfaceColor = Color(0xFF1A1A1A); // Slightly lighter surface
  static const _errorColor = Color(0xFFEF4444); // Modern red

  // Text colors with better contrast
  static const _onPrimaryColor = Colors.white;
  static const _onSecondaryColor = Colors.white;
  static const _onSurfaceColor = Colors.white;
  static const _onErrorColor = Colors.white;

  static ThemeData get defaultTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme(
        brightness: Brightness.dark,
        primary: _primaryColor,
        onPrimary: _onPrimaryColor,
        secondary: _secondaryColor,
        onSecondary: _onSecondaryColor,
        error: _errorColor,
        onError: _onErrorColor,
        surface: _surfaceColor,
        onSurface: _onSurfaceColor,
      ),
      // Updated typography for modern look
      textTheme: const TextTheme(
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
      ),
      // Updated component themes
      appBarTheme: AppBarTheme(
        backgroundColor: _surfaceColor,
        foregroundColor: _onSurfaceColor,
        shadowColor: _primaryColor.withValues(alpha: 0.1),
      ),
      cardTheme: CardThemeData(
        color: _surfaceColor,
        elevation: 2,
        shadowColor: _primaryColor.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryColor,
          foregroundColor: _onPrimaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 16,
          ),
          elevation: 2,
          shadowColor: _primaryColor.withValues(alpha: 0.3),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _surfaceColor.withValues(alpha: 0.8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: _onSurfaceColor.withValues(alpha: 0.12),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: _primaryColor,
            width: 2,
          ),
        ),
      ),
    );
  }
}
