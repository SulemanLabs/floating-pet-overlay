import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/streak_duration_formatter.dart';
import '../../../../core/widgets/app_card.dart';
import '../../domain/entities/streak_entity.dart';

/// One row in `StreakHistoryScreen` (spec §27): status, start date, the
/// start→end range, and the actual duration — all read straight off the
/// entity's stored timestamps, never recomputed from a tick count.
class StreakHistoryItem extends StatelessWidget {
  const StreakHistoryItem({super.key, required this.streak, this.onDelete});

  final StreakEntity streak;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final dateFormat = DateFormat('MMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');

    final (icon, label, tint) = switch (streak.status) {
      StreakStatus.completed => (Icons.check_circle_rounded, 'Completed', colorScheme.primary),
      StreakStatus.broken => (Icons.cancel_rounded, 'Broken', colorScheme.error),
      StreakStatus.active => (Icons.local_fire_department_rounded, 'Active', colorScheme.primary),
    };

    final endLabel = switch (streak.status) {
      StreakStatus.completed => timeFormat.format(streak.completedAt ?? streak.endDate ?? streak.startDate),
      StreakStatus.broken => timeFormat.format(streak.brokenAt ?? streak.startDate),
      StreakStatus.active => 'now',
    };

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.base),
      child: Row(
        children: [
          Icon(icon, color: tint, size: 22),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.titleSmall?.copyWith(color: tint)),
                const SizedBox(height: 2),
                Text(dateFormat.format(streak.startDate), style: Theme.of(context).textTheme.bodyMedium),
                Text(
                  '${timeFormat.format(streak.startDate)} → $endLabel',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Duration', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant)),
              Text(formatStreakDuration(streak.actualDuration), style: Theme.of(context).textTheme.titleSmall),
            ],
          ),
          if (onDelete != null) ...[
            const SizedBox(width: AppSpacing.xs),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              tooltip: 'Delete',
              onPressed: onDelete,
              iconSize: 20,
            ),
          ],
        ],
      ),
    );
  }
}
