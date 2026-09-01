import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_banner.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_section_header.dart';
import '../providers/streak_providers.dart';
import '../widgets/current_streak_card.dart';
import '../widgets/streak_duration_selector.dart';
import '../widgets/streak_stats_card.dart';

/// The streak dashboard (spec §23): current streak (or a "start" prompt),
/// dashboard stats, and a link into the full history.
class StreakScreen extends ConsumerWidget {
  const StreakScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streakAsync = ref.watch(streakControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Streak'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'History',
            onPressed: () => context.push(AppRoutes.streakHistory),
          ),
        ],
      ),
      body: streakAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('Failed to load streak: $error')),
        data: (state) => RefreshIndicator(
          onRefresh: () => ref.read(streakControllerProvider.notifier).refresh(),
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.base),
            children: [
              if (state.errorMessage != null) ...[
                AppBanner(
                  title: 'Heads up',
                  message: state.errorMessage!,
                  variant: AppBannerVariant.error,
                  onTap: () => ref.read(streakControllerProvider.notifier).clearError(),
                ),
                const SizedBox(height: AppSpacing.base),
              ],
              if (state.current != null)
                CurrentStreakCard(streak: state.current!)
              else
                AppEmptyState(
                  icon: Icons.local_fire_department_rounded,
                  title: 'No active streak',
                  message: 'Start one open-ended, or set a duration to count down.',
                  actionLabel: 'Start Streak',
                  onAction: () => showStreakDurationSelector(
                    context,
                    onSelect: (duration) => ref.read(streakControllerProvider.notifier).start(duration: duration),
                  ),
                ),
              const SizedBox(height: AppSpacing.xl),
              const AppSectionHeader('Stats'),
              StreakStatsCard(stats: state.stats),
              if (state.current != null) ...[
                const SizedBox(height: AppSpacing.xl),
                AppButton(
                  label: 'View history',
                  variant: AppButtonVariant.secondary,
                  icon: Icons.history_rounded,
                  onPressed: () => context.push(AppRoutes.streakHistory),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
