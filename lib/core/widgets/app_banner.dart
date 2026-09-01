import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

enum AppBannerVariant { info, warning, error }

/// Inline callout for a message that needs the user's attention (missing
/// permission, a load failure, a validation problem) — icon, title,
/// message, and an optional tap action, styled by semantic color rather
/// than the generic Material error container.
class AppBanner extends StatelessWidget {
  const AppBanner({
    super.key,
    required this.title,
    required this.message,
    this.variant = AppBannerVariant.warning,
    this.onTap,
  });

  final String title;
  final String message;
  final AppBannerVariant variant;
  final VoidCallback? onTap;

  (Color, Color, IconData) _look(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return switch (variant) {
      AppBannerVariant.info => (
          isDark ? AppColors.darkInfo : AppColors.info,
          isDark ? const Color(0x267CA8FF) : const Color(0x144F8CFF),
          Icons.info_outline,
        ),
      AppBannerVariant.warning => (
          isDark ? AppColors.darkWarning : AppColors.warning,
          isDark ? const Color(0x26FFA940) : const Color(0x14F79009),
          Icons.warning_amber_rounded,
        ),
      AppBannerVariant.error => (
          isDark ? AppColors.darkError : AppColors.error,
          isDark ? const Color(0x26FF6B70) : const Color(0x14E5484D),
          Icons.error_outline,
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (accent, tint, icon) = _look(theme.brightness);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: AppRadius.lgRadius,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.base),
          decoration: BoxDecoration(
            color: tint,
            borderRadius: AppRadius.lgRadius,
            border: Border.all(color: accent.withValues(alpha: 0.25)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: accent),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleSmall?.copyWith(color: accent)),
                    const SizedBox(height: 2),
                    Text(message, style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
              if (onTap != null) ...[
                const SizedBox(width: AppSpacing.sm),
                Icon(Icons.chevron_right, color: accent),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
