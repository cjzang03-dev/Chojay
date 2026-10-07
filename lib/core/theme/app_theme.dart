import 'package:flutter/material.dart';

/// "Serene Himalayan Green" — the shared visual identity with the
/// journeyinbhutan.com website. Keep this the single source of brand color
/// so the app and site stay visually consistent as both evolve.
class AppColors {
  const AppColors._();

  static const himalayanGreen = Color(0xFF1F5C4A);
  static const himalayanGreenDark = Color(0xFF123B2F);
  static const himalayanGreenLight = Color(0xFF2E7D63);
  static const saffron = Color(0xFFD98E29); // accent, used sparingly
  static const cloudWhite = Color(0xFFFAF9F5);
  static const mist = Color(0xFFF0EFE9); // subtle fills, skeletons
  static const stoneGrey = Color(0xFF6B7268);
  static const stoneGreyLight = Color(0xFF9CA39A);
  static const errorRed = Color(0xFFB3261E);
  static const starGold = Color(0xFFF2B705);
}

/// A small consistent spacing scale, so padding/gaps read as one system
/// rather than ad-hoc magic numbers scattered per screen.
class AppSpacing {
  const AppSpacing._();

  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
}

class AppRadius {
  const AppRadius._();

  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 20.0;
  static const pill = 999.0;
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
      surface: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.cloudWhite,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.cloudWhite,
        foregroundColor: AppColors.himalayanGreenDark,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.himalayanGreenDark,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.himalayanGreen,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.himalayanGreen.withValues(alpha: 0.4),
          minimumSize: const Size.fromHeight(54),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.1,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.himalayanGreenDark,
          minimumSize: const Size.fromHeight(54),
          side: const BorderSide(color: AppColors.stoneGreyLight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.himalayanGreen,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.himalayanGreenDark,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.mist,
        selectedColor: AppColors.himalayanGreen,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          color: AppColors.himalayanGreenDark,
        ),
        secondaryLabelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          side: BorderSide.none,
        ),
        side: BorderSide.none,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.mist,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.himalayanGreen, width: 1.5),
        ),
        hintStyle: const TextStyle(color: AppColors.stoneGreyLight),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        elevation: 0,
        height: 68,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.himalayanGreen.withValues(alpha: 0.12),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? AppColors.himalayanGreenDark : AppColors.stoneGrey,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? AppColors.himalayanGreen : AppColors.stoneGrey,
          );
        }),
      ),
      dividerTheme: DividerThemeData(
        color: Colors.black.withValues(alpha: 0.06),
        thickness: 1,
        space: 1,
      ),
      textTheme: const TextTheme(
        displaySmall: TextStyle(
          fontWeight: FontWeight.w800,
          color: AppColors.himalayanGreenDark,
          letterSpacing: -0.5,
        ),
        headlineMedium: TextStyle(
          fontWeight: FontWeight.w800,
          color: AppColors.himalayanGreenDark,
          letterSpacing: -0.3,
        ),
        headlineSmall: TextStyle(
          fontWeight: FontWeight.w700,
          color: AppColors.himalayanGreenDark,
        ),
        titleLarge: TextStyle(fontWeight: FontWeight.w700),
        titleMedium: TextStyle(fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(height: 1.4),
        bodyMedium: TextStyle(height: 1.4, color: AppColors.stoneGrey),
        labelLarge: TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }
}
