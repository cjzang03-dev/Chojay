import 'package:flutter/material.dart';

/// "Serene Himalayan Green" — the shared visual identity with the
/// journeyinbhutan.com website. Keep this the single source of brand color
/// so the app and site stay visually consistent as both evolve.
class AppColors {
  const AppColors._();

  static const himalayanGreen = Color(0xFF1F5C4A);
  static const himalayanGreenDark = Color(0xFF123B2F);
  static const saffron = Color(0xFFD98E29); // accent, used sparingly
  static const cloudWhite = Color(0xFFFAF9F5);
  static const stoneGrey = Color(0xFF6B7268);
  static const errorRed = Color(0xFFB3261E);
}

class AppTheme {
  const AppTheme._();

  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.himalayanGreen,
      brightness: Brightness.light,
      primary: AppColors.himalayanGreen,
      secondary: AppColors.saffron,
      error: AppColors.errorRed,
      surface: AppColors.cloudWhite,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.cloudWhite,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.cloudWhite,
        foregroundColor: AppColors.himalayanGreenDark,
        elevation: 0,
        centerTitle: false,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.himalayanGreen,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          side: const BorderSide(color: AppColors.stoneGrey),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
        ),
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          fontWeight: FontWeight.w700,
          color: AppColors.himalayanGreenDark,
        ),
        titleLarge: TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }
}
