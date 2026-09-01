import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';

enum AppStatusTone { success, warning, neutral }

/// Small colored pill for a status label (e.g. Active / Starting / Stopped).
/// Uses the semantic success/warning colors instead of raw [Colors.green]
/// etc. so the palette stays centralized.
class AppStatusChip extends StatelessWidget {
  const AppStatusChip({super.key, required this.label, required this.tone});

  final String label;
  final AppStatusTone tone;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final color = switch (tone) {
      AppStatusTone.success => isDark ? AppColors.darkSuccess : AppColors.success,
      AppStatusTone.warning => isDark ? AppColors.darkWarning : AppColors.warning,
      AppStatusTone.neutral => AppColors.neutral,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: AppRadius.pillRadius),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(label, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: color)),
        ],
      ),
    );
  }
}
