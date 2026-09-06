import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_confirm_dialog.dart';
import '../../domain/entities/streak_entity.dart';
import '../controllers/streak_countdown_controller.dart';
import '../providers/streak_providers.dart';
import 'streak_countdown.dart';
import 'streak_progress_indicator.dart';

/// The dashboard's hero card for the active streak (spec §24). Renders
/// nothing when there's no active streak — `StreakScreen` shows the "Start a
/// streak" entry point instead in that case.
class CurrentStreakCard extends ConsumerWidget {
  const CurrentStreakCard({super.key, required this.streak});

  final StreakEntity streak;

  Future<void> _confirmBreak(BuildContext context, WidgetRef ref) async {
    final confirmed = await showAppConfirmDialog(
      context,
      title: 'Break current streak?',
      message: 'Your current streak will be marked as broken and saved to history.',
      confirmLabel: 'Break streak',
      isDestructive: true,
    );
    if (confirmed) await ref.read(streakControllerProvider.notifier).breakCurrent();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final countdown = ref.watch(streakCountdownProvider);

    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl, horizontal: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.local_fire_department_outlined, size: 20, color: colorScheme.onSurface),
              const SizedBox(width: AppSpacing.xs),
              Text('Current Streak', style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Center(
            child: countdown == null
                ? const SizedBox.shrink()
                : StreakCountdown(
                    value: countdown,
                    includeSeconds: false,
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Center(
            child: Text(
              streak.isOpenEnded ? 'elapsed' : 'remaining',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
          ),
          const SizedBox(height: AppSpacing.base),
          Center(
            child: Text(
              streak.isOpenEnded ? 'Open-ended' : 'Ends at ${DateFormat('h:mm a').format(streak.endDate!)}',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(color: colorScheme.primary),
            ),
          ),
          if (streak.isTimed) ...[
            const SizedBox(height: AppSpacing.base),
            StreakProgressIndicator(streak: streak),
          ],
          const SizedBox(height: AppSpacing.xl),
          // Stacked, full-width — "Complete" is the primary action a user
          // wants for an open-ended streak, so it gets the filled/prominent
          // style; "Break" stays a plain tertiary button since it's the
          // negative/exit action (its own confirmation dialog is where the
          // destructive framing actually lives).
          if (streak.isOpenEnded) ...[
            AppButton(
              label: 'Complete',
              icon: Icons.check_circle_outline_rounded,
              onPressed: () => ref.read(streakControllerProvider.notifier).completeCurrent(),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          AppButton(
            label: 'Break',
            variant: AppButtonVariant.tertiary,
            icon: Icons.close_rounded,
            onPressed: () => _confirmBreak(context, ref),
          ),
        ],
      ),
    );
  }
}
