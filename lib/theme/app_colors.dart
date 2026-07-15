import 'package:flutter/material.dart';

/// Central color palette for the BodyX dark-neon design system.
class AppColors {
  AppColors._();

  // Backgrounds
  static const Color background = Color(0xFF0E0E11);
  static const Color surface = Color(0xFF15151C);
  static const Color surfaceElevated = Color(0xFF1B1B24);
  static const Color card = Color(0xFF1C1C26);
  static const Color cardBorder = Color(0xFF2A2A36);

  // Brand / accent
  static const Color primary = Color(0xFF9D4EDD);
  static const Color primaryDeep = Color(0xFF6A2BE2);
  static const Color primaryBright = Color(0xFFB794F6);
  static const Color primarySoft = Color(0xFF2A1E45);

  // Secondary accents
  static const Color warning = Color(0xFFFF6B4A);
  static const Color warningDeep = Color(0xFFE23E57);
  static const Color success = Color(0xFF3DDC97);
  static const Color info = Color(0xFF4EA8DE);
  static const Color gold = Color(0xFFFFC94D);

  /// Point accent — used sparingly (a badge, an icon, a selected state),
  /// never as a gradient partner for [primary].
  static const Color pink = Color(0xFFEC6FA9);

  // Text
  static const Color textPrimary = Color(0xFFF5F5FA);
  static const Color textSecondary = Color(0xFFA0A0B2);
  static const Color textMuted = Color(0xFF6B6B7B);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Gradients
  static const List<Color> primaryGradient = [
    Color(0xFFB388FF),
    Color(0xFF9D4EDD),
    Color(0xFF6A2BE2),
  ];

  static const List<Color> warningGradient = [
    Color(0xFFFF9466),
    Color(0xFFFF6B4A),
  ];

  static const List<Color> backgroundGradient = [
    Color(0xFF17171F),
    Color(0xFF0E0E11),
  ];

  static const Color divider = Color(0xFF25252F);

  // Muscle-zone heat colors
  static const Color zoneNeutral = Color(0x33B794F6);
  static const Color zoneActive = Color(0xFFFF6B4A);
  static const Color zoneSelected = Color(0xFF9D4EDD);
}
