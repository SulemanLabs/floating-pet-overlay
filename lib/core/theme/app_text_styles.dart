import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// App-wide type scale. Headings use Baloo 2 (rounded, playful); body/UI
/// copy uses Inter (clean, highly readable). Build a [TextTheme] per
/// brightness with [textTheme] and read named looks off it via
/// `Theme.of(context).textTheme`.
abstract final class AppTextStyles {
  static TextStyle _display({required double size, required Color color, FontWeight weight = FontWeight.w700}) =>
      GoogleFonts.baloo2(fontSize: size, fontWeight: weight, color: color, height: 1.2, letterSpacing: -0.2);

  static TextStyle _body({
    required double size,
    required Color color,
    FontWeight weight = FontWeight.w400,
    double letterSpacing = 0,
    double height = 1.4,
  }) =>
      GoogleFonts.inter(fontSize: size, fontWeight: weight, color: color, height: height, letterSpacing: letterSpacing);

  static TextTheme textTheme(Brightness brightness) {
    final primary = brightness == Brightness.dark ? AppColors.darkTextPrimary : AppColors.darkText;
    final secondary = brightness == Brightness.dark ? AppColors.darkSecondaryText : AppColors.secondaryText;

    return TextTheme(
      // Headlines / titles — Baloo 2
      displayLarge: _display(size: 34, color: primary),
      displayMedium: _display(size: 28, color: primary),
      headlineLarge: _display(size: 26, color: primary),
      headlineMedium: _display(size: 22, color: primary),
      headlineSmall: _display(size: 20, color: primary),
      titleLarge: _display(size: 18, color: primary, weight: FontWeight.w600),
      titleMedium: _body(size: 16, color: primary, weight: FontWeight.w600, letterSpacing: 0.1),
      titleSmall: _body(size: 14, color: primary, weight: FontWeight.w600, letterSpacing: 0.1),

      // Body / labels — Inter
      bodyLarge: _body(size: 16, color: primary, height: 1.5),
      bodyMedium: _body(size: 14, color: secondary, height: 1.5),
      bodySmall: _body(size: 12, color: secondary, height: 1.4),
      labelLarge: _body(size: 15, color: primary, weight: FontWeight.w600, letterSpacing: 0.1),
      labelMedium: _body(size: 13, color: secondary, weight: FontWeight.w600, letterSpacing: 0.2),
      labelSmall: _body(size: 11, color: secondary, weight: FontWeight.w600, letterSpacing: 0.3),
    );
  }
}
