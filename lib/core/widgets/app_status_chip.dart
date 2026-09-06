import 'package:flutter/material.dart';

import '../theme/app_radius.dart';

enum AppStatusTone { success, warning, neutral }

/// Small monochrome pill for a status label (e.g. Active / Starting /
/// Stopped). Tone is conveyed by weight (solid black vs. muted gray dot),
/// not hue, to stay within the monochrome palette.
class AppStatusChip extends StatelessWidget {
  const AppStatusChip({super.key, required this.label, required this.tone});

  final String label;
  final AppStatusTone tone;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final color = switch (tone) {
      AppStatusTone.success => colorScheme.onSurface,
      AppStatusTone.warning => colorScheme.onSurfaceVariant,
      AppStatusTone.neutral => colorScheme.onSurfaceVariant,
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
