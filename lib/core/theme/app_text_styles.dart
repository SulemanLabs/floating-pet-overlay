import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// App-wide type scale. A single clean sans-serif (Plus Jakarta Sans) is used
/// throughout — hierarchy comes from weight and size, not from mixing font
/// families. Build a [TextTheme] per brightness with [textTheme] and read
/// named looks off it via `Theme.of(context).textTheme`.
abstract final class AppTextStyles {
  static TextStyle _text({
    required double size,
    required Color color,
    FontWeight weight = FontWeight.w400,
    double letterSpacing = 0,
    double height = 1.4,
  }) =>
      GoogleFonts.plusJakartaSans(fontSize: size, fontWeight: weight, color: color, height: height, letterSpacing: letterSpacing);

  static TextTheme textTheme(Brightness brightness) {
    final primary = brightness == Brightness.dark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final secondary = brightness == Brightness.dark ? AppColors.darkTextSecondary : AppColors.textSecondary;

    return TextTheme(
      // Headings — bold, tight, comfortable line height
      displayLarge: _text(size: 34, color: primary, weight: FontWeight.w700, height: 1.2, letterSpacing: -0.3),
      displayMedium: _text(size: 28, color: primary, weight: FontWeight.w700, height: 1.2, letterSpacing: -0.2),
      headlineLarge: _text(size: 26, color: primary, weight: FontWeight.w700, height: 1.25, letterSpacing: -0.2),
      headlineMedium: _text(size: 22, color: primary, weight: FontWeight.w700, height: 1.25),
      headlineSmall: _text(size: 20, color: primary, weight: FontWeight.w600, height: 1.3),
      titleLarge: _text(size: 18, color: primary, weight: FontWeight.w600, height: 1.3),
      titleMedium: _text(size: 16, color: primary, weight: FontWeight.w600, height: 1.4, letterSpacing: 0.1),
      titleSmall: _text(size: 14, color: primary, weight: FontWeight.w600, height: 1.4, letterSpacing: 0.1),

      // Body / labels
      bodyLarge: _text(size: 16, color: primary, height: 1.5),
      bodyMedium: _text(size: 14, color: secondary, height: 1.5),
      bodySmall: _text(size: 12, color: secondary, height: 1.4),
      labelLarge: _text(size: 15, color: primary, weight: FontWeight.w600, letterSpacing: 0.1),
      labelMedium: _text(size: 13, color: secondary, weight: FontWeight.w600, letterSpacing: 0.2),
      labelSmall: _text(size: 11, color: secondary, weight: FontWeight.w600, letterSpacing: 0.3),
    );
  }
}
