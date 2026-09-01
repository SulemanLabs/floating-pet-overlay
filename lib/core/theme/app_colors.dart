import 'package:flutter/material.dart';

/// Central color palette. Screens and widgets should reference these
/// constants (or `Theme.of(context).colorScheme` where a semantic role is
/// enough) instead of hardcoding colors.
abstract final class AppColors {
  // Brand — light
  static const primaryPink = Color(0xFFF45B9A);
  static const deepPink = Color(0xFFD93678);
  static const lightPink = Color(0xFFFCE1EC);
  static const softBackground = Color(0xFFFFF4F8);
  static const veryLightPink = Color(0xFFFFF9FB);
  static const accentPink = Color(0xFFFF78AE);

  static const darkText = Color(0xFF241923);
  static const secondaryText = Color(0xFF766872);
  static const border = Color(0xFFF1D5E1);
  static const white = Color(0xFFFFFFFF);

  static const success = Color(0xFF32B768);
  static const warning = Color(0xFFF79009);
  static const error = Color(0xFFE5484D);
  static const info = Color(0xFF4F8CFF);
  static const neutral = Color(0xFF9A8E96);

  // Brand — dark (hand-tuned, not an inversion of the light set)
  static const darkBackground = Color(0xFF1A1417);
  static const darkSurface = Color(0xFF241923);
  static const darkSurfaceElevated = Color(0xFF2E2028);
  static const darkPrimaryPink = Color(0xFFFF7CB4);
  static const darkAccentPink = Color(0xFFFF93C2);
  static const darkBorder = Color(0x33F1D5E1);
  static const darkTextPrimary = Color(0xFFF5EDF1);
  static const darkSecondaryText = Color(0xFFC9B9C2);

  static const darkSuccess = Color(0xFF4FD98A);
  static const darkWarning = Color(0xFFFFA940);
  static const darkError = Color(0xFFFF6B70);
  static const darkInfo = Color(0xFF7CA8FF);
}
