import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.scaffoldBackground,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.accentPill,
        onPrimary: AppColors.buttonText,
        surface: AppColors.cardSurface,
        onSurface: AppColors.textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.headerBackground,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      textTheme: TextTheme(
        headlineLarge: GoogleFonts.italiana(
          color: AppColors.textPrimary,
          fontSize: 36,
          fontWeight: FontWeight.w400,
        ),
        headlineMedium: GoogleFonts.italiana(
          color: AppColors.textPrimary,
          fontSize: 24,
          fontWeight: FontWeight.w400,
        ),
        bodyLarge: GoogleFonts.italiana(
          color: AppColors.textPrimary,
          fontSize: 16,
          height: 1.4,
        ),
        bodyMedium: GoogleFonts.italiana(
          color: AppColors.textPrimary,
          fontSize: 14,
          height: 1.43,
        ),
        bodySmall: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
        ),
      ),
    );
  }
}
