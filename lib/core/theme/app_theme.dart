import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_radius.dart';
import 'app_text_styles.dart';

/// Builds the light/dark [ThemeData] pair for the app from [AppColors] and
/// [AppTextStyles]. Component themes are defined here so screens get the
/// design system "for free" through `Theme.of(context)` rather than
/// re-declaring styling per widget. Warm pet theme: gold/orange primary with
/// a sky blue secondary accent, on a soft cream background, with a single
/// restrained red reserved for destructive/error states.
class AppTheme {
  const AppTheme._();

  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final colorScheme = isDark
        ? const ColorScheme.dark(
            primary: AppColors.primary,
            onPrimary: AppColors.darkBackground,
            primaryContainer: AppColors.darkSurfaceElevated,
            onPrimaryContainer: AppColors.primary,
            secondary: AppColors.secondary,
            onSecondary: AppColors.darkBackground,
            secondaryContainer: AppColors.darkSurfaceElevated,
            onSecondaryContainer: AppColors.secondary,
            surface: AppColors.darkSurface,
            onSurface: AppColors.darkTextPrimary,
            surfaceContainerHighest: AppColors.darkSurfaceElevated,
            onSurfaceVariant: AppColors.darkTextSecondary,
            outline: AppColors.darkBorder,
            outlineVariant: AppColors.darkDivider,
            error: AppColors.darkError,
            onError: AppColors.darkBackground,
            errorContainer: AppColors.darkErrorContainer,
            onErrorContainer: AppColors.darkError,
          )
        : const ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: AppColors.textPrimary,
            primaryContainer: AppColors.lightBackground,
            onPrimaryContainer: AppColors.primary,
            secondary: AppColors.secondary,
            onSecondary: AppColors.textPrimary,
            secondaryContainer: AppColors.lightBackground,
            onSecondaryContainer: AppColors.textPrimary,
            surface: AppColors.white,
            onSurface: AppColors.textPrimary,
            surfaceContainerHighest: AppColors.lightBackground,
            onSurfaceVariant: AppColors.textSecondary,
            outline: AppColors.border,
            outlineVariant: AppColors.divider,
            error: AppColors.error,
            onError: AppColors.white,
            errorContainer: AppColors.errorContainer,
            onErrorContainer: AppColors.error,
          );

    final scaffoldBackground = isDark ? AppColors.darkBackground : AppColors.background;
    final cardSurface = isDark ? AppColors.darkSurface : AppColors.white;
    final disabledBackground = isDark ? AppColors.darkDisabled : AppColors.disabled;
    final disabledForeground = isDark ? AppColors.darkTextMuted : AppColors.textMuted;
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
          disabledBackgroundColor: disabledBackground,
          disabledForegroundColor: disabledForeground,
          minimumSize: const Size.fromHeight(52),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          textStyle: textTheme.labelLarge?.copyWith(color: colorScheme.onPrimary),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.pillRadius),
          elevation: 0,
        ),
      ),

      // Doubles as the "Outline Button" from the spec: white/black surface,
      // solid border in the foreground color, no fill.
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.onSurface,
          disabledForegroundColor: disabledForeground,
          minimumSize: const Size.fromHeight(52),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          side: BorderSide(color: colorScheme.onSurface),
          textStyle: textTheme.labelLarge?.copyWith(color: colorScheme.onSurface),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.pillRadius),
        ).copyWith(
          side: WidgetStateProperty.resolveWith(
            (states) => BorderSide(color: states.contains(WidgetState.disabled) ? colorScheme.outline : colorScheme.onSurface),
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.onSurface,
          disabledForegroundColor: disabledForeground,
          minimumSize: const Size(0, 44),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          textStyle: textTheme.labelLarge?.copyWith(color: colorScheme.onSurface),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.mdRadius),
        ),
      ),

      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: colorScheme.onSurface),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: textTheme.bodyMedium?.copyWith(color: isDark ? AppColors.darkTextMuted : AppColors.textMuted),
        labelStyle: textTheme.bodyMedium,
        floatingLabelStyle: textTheme.labelLarge?.copyWith(color: colorScheme.onSurface),
        border: OutlineInputBorder(borderRadius: AppRadius.mdRadius, borderSide: BorderSide(color: colorScheme.outline)),
        enabledBorder: OutlineInputBorder(borderRadius: AppRadius.mdRadius, borderSide: BorderSide(color: colorScheme.outline)),
        focusedBorder: OutlineInputBorder(borderRadius: AppRadius.mdRadius, borderSide: BorderSide(color: colorScheme.onSurface, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: AppRadius.mdRadius, borderSide: BorderSide(color: colorScheme.error)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: AppRadius.mdRadius, borderSide: BorderSide(color: colorScheme.error, width: 1.5)),
        errorStyle: textTheme.bodySmall?.copyWith(color: colorScheme.error),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? colorScheme.primary : colorScheme.surface,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? colorScheme.primary.withValues(alpha: 0.4) : colorScheme.surfaceContainerHighest,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? Colors.transparent : colorScheme.outline,
        ),
      ),

      sliderTheme: SliderThemeData(
        activeTrackColor: colorScheme.primary,
        inactiveTrackColor: colorScheme.surfaceContainerHighest,
        thumbColor: colorScheme.primary,
        overlayColor: colorScheme.primary.withValues(alpha: 0.1),
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
        selectedColor: colorScheme.primary,
        secondarySelectedColor: colorScheme.primary,
        checkmarkColor: colorScheme.onPrimary,
        disabledColor: colorScheme.surfaceContainerHighest,
        labelStyle: textTheme.labelMedium?.copyWith(color: colorScheme.onSurface),
        secondaryLabelStyle: textTheme.labelMedium?.copyWith(color: colorScheme.onPrimary),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.pillRadius),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: cardSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.xlRadius, side: BorderSide(color: colorScheme.outlineVariant)),
        titleTextStyle: textTheme.headlineSmall,
        contentTextStyle: textTheme.bodyMedium,
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: cardSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        modalElevation: 0,
        showDragHandle: true,
        dragHandleColor: colorScheme.outline,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xxl))),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? AppColors.darkSurfaceElevated : AppColors.textPrimary,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: AppColors.white),
        actionTextColor: AppColors.white,
        behavior: SnackBarBehavior.floating,
        elevation: 1,
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
        circularTrackColor: colorScheme.surfaceContainerHighest,
        linearTrackColor: colorScheme.surfaceContainerHighest,
      ),

      dividerTheme: DividerThemeData(color: colorScheme.outlineVariant, thickness: 1, space: 1),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 1,
        focusElevation: 1,
        hoverElevation: 2,
        highlightElevation: 2,
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
