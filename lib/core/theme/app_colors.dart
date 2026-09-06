import 'package:flutter/material.dart';

/// Central color palette — warm, pet-themed light system built around gold
/// and sky blue accents on a soft cream background. Screens and widgets
/// should reference these constants (or `Theme.of(context).colorScheme`
/// where a semantic role is enough) instead of hardcoding colors.
abstract final class AppColors {
  // Light theme
  static const primary = Color(0xFFFFAE42); // Pet Gold/Orange
  static const secondary = Color(0xFF87CEEB); // Sky Blue Accent
  static const background = Color(0xFFFFFDF7); // Soft Cream
  static const textPrimary = Color(0xFF2D2420); // Warm Espresso
  static const textSecondary = Color(0xFF6B5D53);
  static const textMuted = Color(0xFF9C9086);
  static const lightBackground = Color(0xFFFBF3E3);
  static const divider = Color(0xFFEDE3D3);
  static const border = Color(0xFFE6DAC5);
  static const disabled = Color(0xFFDCD2C2);
  static const white = Color(0xFFFFFFFF);

  static const error = Color(0xFFD64545);
  static const errorContainer = Color(0xFFF7E2E2);

  // Dark theme (hand-tuned hierarchy, not a plain inversion)
  static const darkBackground = Color(0xFF1C1712);
  static const darkSurface = Color(0xFF241E17);
  static const darkSurfaceElevated = Color(0xFF2E261D);
  static const darkTextPrimary = Color(0xFFFFFDF7);
  static const darkTextSecondary = Color(0xFFC9BEB1);
  static const darkTextMuted = Color(0xFF8A7F72);
  static const darkDivider = Color(0xFF3A3025);
  static const darkBorder = Color(0xFF453A2C);
  static const darkDisabled = Color(0xFF4D4335);

  static const darkError = Color(0xFFE57373);
  static const darkErrorContainer = Color(0xFF2E1717);
}
