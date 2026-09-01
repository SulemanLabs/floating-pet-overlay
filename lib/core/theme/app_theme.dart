import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_radius.dart';
import 'app_text_styles.dart';

/// Builds the light/dark [ThemeData] pair for the app from [AppColors] and
/// [AppTextStyles]. Component themes are defined here so screens get the
/// design system "for free" through `Theme.of(context)` rather than
/// re-declaring styling per widget.
class AppTheme {
  const AppTheme._();

  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final colorScheme = isDark
        ? const ColorScheme.dark(
            primary: AppColors.darkPrimaryPink,
            onPrimary: AppColors.darkText,
            primaryContainer: AppColors.darkSurfaceElevated,
            onPrimaryContainer: AppColors.darkPrimaryPink,
            secondary: AppColors.darkAccentPink,
            onSecondary: AppColors.darkText,
            secondaryContainer: AppColors.darkSurfaceElevated,
            onSecondaryContainer: AppColors.darkAccentPink,
            surface: AppColors.darkSurface,
            onSurface: AppColors.darkTextPrimary,
            surfaceContainerHighest: AppColors.darkSurfaceElevated,
            onSurfaceVariant: AppColors.darkSecondaryText,
            outline: AppColors.darkBorder,
            outlineVariant: AppColors.darkBorder,
            error: AppColors.darkError,
            onError: AppColors.darkText,
            errorContainer: Color(0x33FF6B70),
            onErrorContainer: AppColors.darkError,
          )
        : const ColorScheme.light(
            primary: AppColors.primaryPink,
            onPrimary: AppColors.white,
            primaryContainer: AppColors.lightPink,
            onPrimaryContainer: AppColors.deepPink,
            secondary: AppColors.accentPink,
            onSecondary: AppColors.white,
            secondaryContainer: AppColors.lightPink,
            onSecondaryContainer: AppColors.deepPink,
            surface: AppColors.white,
            onSurface: AppColors.darkText,
            surfaceContainerHighest: AppColors.veryLightPink,
            onSurfaceVariant: AppColors.secondaryText,
            outline: AppColors.border,
            outlineVariant: AppColors.border,
            error: AppColors.error,
            onError: AppColors.white,
            errorContainer: Color(0x1AE5484D),
            onErrorContainer: AppColors.error,
          );

    final scaffoldBackground = isDark ? AppColors.darkBackground : AppColors.softBackground;
    final cardSurface = isDark ? AppColors.darkSurface : AppColors.white;
    final textTheme = AppTextStyles.textTheme(brightness);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffoldBackground,
      textTheme: textTheme,
      splashFactory: InkSparkle.splashFactory,

      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: scaffoldBackground,
        surfaceTintColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: textTheme.headlineSmall,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
      ),

      cardTheme: CardThemeData(
        color: cardSurface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lgRadius, side: BorderSide(color: colorScheme.outlineVariant)),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          disabledBackgroundColor: colorScheme.primary.withValues(alpha: 0.4),
          disabledForegroundColor: colorScheme.onPrimary.withValues(alpha: 0.7),
          minimumSize: const Size.fromHeight(52),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          textStyle: textTheme.labelLarge?.copyWith(color: colorScheme.onPrimary),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.pillRadius),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          disabledForegroundColor: colorScheme.primary.withValues(alpha: 0.4),
          minimumSize: const Size.fromHeight(52),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          side: BorderSide(color: colorScheme.primary.withValues(alpha: 0.4)),
          textStyle: textTheme.labelLarge?.copyWith(color: colorScheme.primary),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.pillRadius),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          disabledForegroundColor: colorScheme.primary.withValues(alpha: 0.4),
          minimumSize: const Size(0, 44),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          textStyle: textTheme.labelLarge?.copyWith(color: colorScheme.primary),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.mdRadius),
        ),
      ),

      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: colorScheme.onSurface),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.darkSurfaceElevated : AppColors.veryLightPink,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: textTheme.bodyMedium,
        labelStyle: textTheme.bodyMedium,
        floatingLabelStyle: textTheme.labelLarge?.copyWith(color: colorScheme.primary),
        border: OutlineInputBorder(borderRadius: AppRadius.mdRadius, borderSide: BorderSide(color: colorScheme.outlineVariant)),
        enabledBorder: OutlineInputBorder(borderRadius: AppRadius.mdRadius, borderSide: BorderSide(color: colorScheme.outlineVariant)),
        focusedBorder: OutlineInputBorder(borderRadius: AppRadius.mdRadius, borderSide: BorderSide(color: colorScheme.primary, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: AppRadius.mdRadius, borderSide: BorderSide(color: colorScheme.error)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: AppRadius.mdRadius, borderSide: BorderSide(color: colorScheme.error, width: 1.5)),
        errorStyle: textTheme.bodySmall?.copyWith(color: colorScheme.error),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? colorScheme.primary : null,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? colorScheme.primary.withValues(alpha: 0.5) : null,
        ),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),

      sliderTheme: SliderThemeData(
        activeTrackColor: colorScheme.primary,
        inactiveTrackColor: colorScheme.primary.withValues(alpha: 0.15),
        thumbColor: colorScheme.primary,
        overlayColor: colorScheme.primary.withValues(alpha: 0.12),
        valueIndicatorColor: colorScheme.primary,
        valueIndicatorTextStyle: textTheme.labelMedium?.copyWith(color: colorScheme.onPrimary),
      ),

      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? colorScheme.primary : Colors.transparent,
        ),
        checkColor: WidgetStatePropertyAll(colorScheme.onPrimary),
        side: BorderSide(color: colorScheme.outline, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceContainerHighest,
        labelStyle: textTheme.labelMedium?.copyWith(color: colorScheme.onSurface),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.pillRadius),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: cardSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.xlRadius),
        titleTextStyle: textTheme.headlineSmall,
        contentTextStyle: textTheme.bodyMedium,
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: cardSurface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: colorScheme.outline,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xxl))),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? AppColors.darkSurfaceElevated : AppColors.darkText,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: AppColors.white),
        actionTextColor: isDark ? AppColors.darkPrimaryPink : AppColors.accentPink,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.mdRadius),
      ),

      listTileTheme: ListTileThemeData(
        iconColor: colorScheme.onSurfaceVariant,
        titleTextStyle: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600, color: colorScheme.onSurface),
        subtitleTextStyle: textTheme.bodyMedium,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.mdRadius),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        circularTrackColor: colorScheme.primary.withValues(alpha: 0.15),
      ),

      dividerTheme: DividerThemeData(color: colorScheme.outlineVariant, thickness: 1, space: 1),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        extendedTextStyle: textTheme.labelLarge?.copyWith(color: colorScheme.onPrimary),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.pillRadius),
      ),

      datePickerTheme: DatePickerThemeData(
        backgroundColor: cardSurface,
        surfaceTintColor: Colors.transparent,
        headerBackgroundColor: colorScheme.primary,
        headerForegroundColor: colorScheme.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.xlRadius),
      ),

      timePickerTheme: TimePickerThemeData(
        backgroundColor: cardSurface,
        dialHandColor: colorScheme.primary,
        dialBackgroundColor: colorScheme.surfaceContainerHighest,
        hourMinuteTextColor: colorScheme.onSurface,
        entryModeIconColor: colorScheme.primary,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.xlRadius),
      ),
    );
  }
}
