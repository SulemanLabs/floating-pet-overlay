import 'package:flutter/material.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_card.dart';
import '../../domain/entities/streak_stats.dart';

/// Dashboard stats grid (spec §23/§26): longest streak, success rate, broken
/// streaks, total streaks. All values come straight off [StreakStats] —
/// nothing here recomputes anything.
class StreakStatsCard extends StatelessWidget {
  const StreakStatsCard({super.key, required this.stats});

  final StreakStats stats;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  label: 'Longest streak',
                  value: _formatDays(stats.longestStreak),
                  icon: Icons.emoji_events_outlined,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _StatTile(
                  label: 'Success rate',
                  value: '${stats.successRate.round()}%',
                  icon: Icons.trending_up_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  label: 'Broken streaks',
                  value: '${stats.brokenStreaks}',
                  icon: Icons.heart_broken_outlined,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _StatTile(label: 'Total streaks', value: '${stats.totalStreaks}', icon: Icons.list_alt_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _formatDays(Duration duration) {
    if (duration.inDays > 0) {
      final hours = duration.inHours % 24;
      return hours > 0 ? '${duration.inDays}d ${hours}h' : '${duration.inDays}d';
    }
    if (duration.inHours > 0) return '${duration.inHours}h ${duration.inMinutes % 60}m';
    if (duration.inMinutes > 0) return '${duration.inMinutes}m';
    return duration.inSeconds > 0 ? '${duration.inSeconds}s' : '—';
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value, required this.icon});

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(color: colorScheme.surfaceContainerHighest, borderRadius: AppRadius.mdRadius),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: colorScheme.primary),
          const SizedBox(height: AppSpacing.sm),
          Text(value, style: Theme.of(context).textTheme.titleLarge),
          Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}
