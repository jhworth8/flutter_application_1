import 'package:flutter/material.dart';

/// High-contrast, bench-legible visual language for the app.
class AppColors {
  static const court = Color(0xFF1F8A53); // Pickleball court green.
  static const courtDark = Color(0xFF14532D);
  static const ball = Color(0xFFD7F23A); // Optic-yellow accent.
  static const teamA = Color(0xFF2563EB);
  static const teamB = Color(0xFFEA580C);
  static const win = Color(0xFF16A34A);
  static const bench = Color(0xFF334155);
  static const surface = Color(0xFFF1F5F9);
}

class AppTheme {
  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.court,
        primary: AppColors.court,
      ),
      scaffoldBackgroundColor: AppColors.surface,
    );

    return base.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.courtDark,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.court,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(56),
          textStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    );
  }
}
