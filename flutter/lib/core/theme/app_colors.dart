import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary palette extracted 1:1 from Figma StudyCrowd designs
  static const Color scaffoldBackground = Color(0xFF426558); // Sage / Forest Green (r:0.259, g:0.397, b:0.344)
  static const Color headerBackground = Color(0xFF1A2918);   // Dark Pine / Header (r:0.101, g:0.160, b:0.096)
  static const Color accentPill = Color(0xFF8DB194);         // Muted Sage Highlight (r:0.552, g:0.693, b:0.580)
  
  // Surfaces and Cards
  static const Color cardSurface = Color(0xFF334E44);
  static const Color bottomNavSurface = Color(0xFF263B33);

  // Text Colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFCBC0C0);      // Subtext and timestamps (r:0.795, g:0.737, b:0.737)
  static const Color textMuted = Color(0xFF9EABA4);

  // Third-party Auth
  static const Color discordBlurple = Color(0xFF5865F2);

  // Status & Actions
  static const Color buttonPrimary = Color(0xFF8DB194);
  static const Color buttonText = Color(0xFF1A2918);
  static const Color iconColor = Color(0xFFFFFFFF);
  static const Color divider = Color(0x33FFFFFF);
}
