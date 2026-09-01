import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_card.dart';
import '../controllers/streak_countdown_controller.dart';
import '../providers/streak_providers.dart';
import 'streak_countdown.dart';

/// Compact HomeScreen entry point (spec §29): the live streak when one is
/// active, or a "Start a Streak" invite otherwise. All the actual streak
/// logic lives in `StreakScreen`/`StreakController` — this only reads and
/// links out.
class HomeStreakCard extends ConsumerWidget {
  const HomeStreakCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(currentStreakProvider);
    final countdown = ref.watch(streakCountdownProvider);
    final colorScheme = Theme.of(context).colorScheme;

    if (current == null || countdown == null) {
      return AppCard(
        onTap: () => context.push(AppRoutes.streak),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('🔥 Start a Streak', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Track your progress with a simple timer.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text('Start →', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: colorScheme.primary)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return AppCard(
      onTap: () => context.push(AppRoutes.streak),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('🔥 Current Streak', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: AppSpacing.xs),
                StreakCountdown(
                  value: countdown,
                  includeSeconds: false,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  countdown.isCountUp ? 'elapsed' : 'remaining',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text('View Streak →', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: colorScheme.primary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
