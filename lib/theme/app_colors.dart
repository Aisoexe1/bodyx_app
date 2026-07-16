import 'package:flutter/material.dart';

/// Central color palette for the BodyX dark-neon design system.
class AppColors {
  AppColors._();

  // Backgrounds — cool near-black with a slight navy tint
  static const Color background = Color(0xFF0A0E14);
  static const Color surface = Color(0xFF10161F);
  static const Color surfaceElevated = Color(0xFF161E2A);
  static const Color card = Color(0xFF141C27);
  static const Color cardBorder = Color(0xFF223140);

  // Brand / accent — electric blue
  static const Color primary = Color(0xFF0E9BD1);
  static const Color primaryDeep = Color(0xFF0A5F87);
  static const Color primaryBright = Color(0xFF5FD8FF);
  static const Color primarySoft = Color(0xFF13293A);

  // Secondary accents
  static const Color warning = Color(0xFFFF6B4A);
  static const Color warningDeep = Color(0xFFE23E57);
  static const Color success = Color(0xFF3DDC97);
  static const Color info = Color(0xFF2DD4BF);
  static const Color gold = Color(0xFFFFC94D);

  /// Point accent — used sparingly (a badge, an icon, a selected state),
  /// never as a gradient partner for [primary].
  static const Color pink = Color(0xFFEC6FA9);

  // Text
  static const Color textPrimary = Color(0xFFF3F6FA);
  static const Color textSecondary = Color(0xFF97A5B8);
  static const Color textMuted = Color(0xFF5E6B7D);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Gradients
  static const List<Color> primaryGradient = [
    Color(0xFF5FD8FF),
    Color(0xFF1AA6E0),
    Color(0xFF0A5F87),
  ];

  static const List<Color> warningGradient = [
    Color(0xFFFF9466),
    Color(0xFFFF6B4A),
  ];

  static const List<Color> backgroundGradient = [
    Color(0xFF141C28),
    Color(0xFF0A0E14),
  ];

  static const Color divider = Color(0xFF1E2A38);

  // Muscle-zone heat colors
  static const Color zoneNeutral = Color(0x335FD8FF);
  static const Color zoneActive = Color(0xFFFF6B4A);
  static const Color zoneSelected = Color(0xFF0E9BD1);
}
