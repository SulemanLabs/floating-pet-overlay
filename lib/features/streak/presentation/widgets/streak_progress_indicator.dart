import 'package:flutter/material.dart';

import '../../../../core/theme/app_radius.dart';
import '../../domain/entities/streak_entity.dart';

/// Timed streaks show `elapsed / duration` as a progress bar. Open-ended
/// streaks have no endpoint to be a percentage of, so this deliberately
/// avoids rendering a misleading progress value for them — a plain "Elapsed
/// time" label instead (spec §25).
class StreakProgressIndicator extends StatelessWidget {
  const StreakProgressIndicator({super.key, required this.streak});

  final StreakEntity streak;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (streak.isOpenEnded) {
      return Text(
        'Elapsed time',
        style: Theme.of(context).textTheme.labelMedium?.copyWith(color: colorScheme.onSurfaceVariant),
      );
    }

    return ClipRRect(
      borderRadius: AppRadius.pillRadius,
      child: LinearProgressIndicator(
        value: streak.progress,
        minHeight: 8,
        backgroundColor: colorScheme.primaryContainer,
        color: colorScheme.primary,
      ),
    );
  }
}
