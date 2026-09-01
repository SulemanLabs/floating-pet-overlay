import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../providers/streak_filter.dart';
import '../providers/streak_providers.dart';
import '../widgets/streak_history_item.dart';

/// Full streak history with status + date filters (spec §27/§28). Filtering
/// is owned by `streakFilterProvider`/`filteredStreakHistoryProvider` — this
/// screen only renders whatever that combination currently produces.
class StreakHistoryScreen extends ConsumerWidget {
  const StreakHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(filteredStreakHistoryProvider);
    final filter = ref.watch(streakFilterProvider);
    final filterController = ref.read(streakFilterProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Streak history')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.base, AppSpacing.sm, AppSpacing.base, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final status in StreakStatusFilter.values)
                        Padding(
                          padding: const EdgeInsets.only(right: AppSpacing.sm),
                          child: ChoiceChip(
                            label: Text(_statusLabel(status)),
                            selected: filter.status == status,
                            onSelected: (_) => filterController.setStatus(status),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final date in StreakDateFilter.values)
                        Padding(
                          padding: const EdgeInsets.only(right: AppSpacing.sm),
                          child: ChoiceChip(
                            label: Text(_dateLabel(date)),
                            selected: filter.date == date,
                            onSelected: (_) => filterController.setDate(date),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: history.isEmpty
                ? const AppEmptyState(
                    icon: Icons.history_rounded,
                    title: 'No streaks here',
                    message: 'Nothing matches this filter yet.',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.base, 0, AppSpacing.base, AppSpacing.huge),
                    itemCount: history.length,
                    separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final streak = history[index];
                      return StreakHistoryItem(
                        streak: streak,
                        onDelete: streak.isActive
                            ? null
                            : () => ref.read(streakControllerProvider.notifier).delete(streak.id),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  static String _statusLabel(StreakStatusFilter status) => switch (status) {
    StreakStatusFilter.all => 'All',
    StreakStatusFilter.active => 'Active',
    StreakStatusFilter.completed => 'Completed',
    StreakStatusFilter.broken => 'Broken',
  };

  static String _dateLabel(StreakDateFilter date) => switch (date) {
    StreakDateFilter.allTime => 'All Time',
    StreakDateFilter.today => 'Today',
    StreakDateFilter.thisWeek => 'This Week',
    StreakDateFilter.thisMonth => 'This Month',
  };
}
