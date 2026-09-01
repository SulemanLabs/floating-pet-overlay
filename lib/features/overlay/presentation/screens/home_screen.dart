import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/deadline_formatter.dart';
import '../../../../core/widgets/app_banner.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_shimmer.dart';
import '../../../../core/widgets/app_status_chip.dart';
import '../../../pets/presentation/widgets/pet_avatar.dart';
import '../../../streak/presentation/widgets/home_streak_card.dart';
import '../../../tasks/presentation/providers/task_providers.dart';
import '../../domain/entities/overlay_status.dart';
import '../providers/overlay_providers.dart';
import '../providers/overlay_state.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overlayAsync = ref.watch(overlayControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Floating Pet Overlay'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.base),
            child: _CircleIconButton(
              icon: Icons.settings_outlined,
              tooltip: 'Settings',
              onPressed: () => context.push(AppRoutes.settings),
            ),
          ),
        ],
      ),
      body: overlayAsync.when(
        loading: () => const _HomeLoading(),
        error: (error, stackTrace) => _HomeError(
          message: error.toString(),
          onRetry: () => ref.read(overlayControllerProvider.notifier).refreshPermissions(),
        ),
        data: (state) => _HomeBody(state: state),
      ),
    );
  }
}

class _HomeLoading extends StatelessWidget {
  const _HomeLoading();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.base),
      children: const [
        AppCard(padding: EdgeInsets.all(AppSpacing.xl), child: AppShimmerHeroCard()),
      ],
    );
  }
}

class _HomeError extends StatelessWidget {
  const _HomeError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 56, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: AppSpacing.base),
            Text('Something went wrong', style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'We couldn\'t load the overlay state. You can try again.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.xl),
            AppButton(label: 'Retry', icon: Icons.refresh_rounded, onPressed: onRetry, expand: false),
          ],
        ),
      ),
    );
  }
}

class _HomeBody extends ConsumerWidget {
  const _HomeBody({required this.state});

  final OverlayUiState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(overlayControllerProvider.notifier);
    final needsPermission = !state.overlayPermissionGranted;
    final tasksAsync = ref.watch(taskControllerProvider);
    final nextTask = tasksAsync.value == null ? null : nextDeadlineTask(tasksAsync.value!);

    return RefreshIndicator(
      onRefresh: controller.refreshPermissions,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.base),
        children: [
          if (needsPermission) ...[
            AppBanner(
              title: 'Overlay permission required',
              message: 'Grant "display over other apps" to start the pet.',
              variant: AppBannerVariant.warning,
              onTap: () => context.push(AppRoutes.permission),
            ),
            const SizedBox(height: AppSpacing.base),
          ],
          if (state.errorMessage != null) ...[
            AppBanner(title: 'Heads up', message: state.errorMessage!, variant: AppBannerVariant.error),
            const SizedBox(height: AppSpacing.base),
          ],
          _PetHeroCard(state: state, controller: controller),
          const SizedBox(height: AppSpacing.base),
          const HomeStreakCard(),
          const SizedBox(height: AppSpacing.base),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _QuickActionTile(
                  icon: Icons.pets_rounded,
                  title: 'Pet library',
                  subtitle: 'Choose a built-in character',
                  onTap: () => context.push(AppRoutes.pets),
                ),
                const Divider(height: 1, indent: AppSpacing.base, endIndent: AppSpacing.base),
                _QuickActionTile(
                  icon: Icons.alarm_rounded,
                  title: 'Task reminders',
                  subtitle: nextTask == null
                      ? 'No active deadline — the pet stays as-is'
                      : '${nextTask.title} — ${formatRelativeDeadline(nextTask.deadline)}',
                  onTap: () => context.push(AppRoutes.tasks),
                ),
                const Divider(height: 1, indent: AppSpacing.base, endIndent: AppSpacing.base),
                _QuickActionTile(
                  icon: Icons.local_fire_department_rounded,
                  title: '🔥 Streak',
                  subtitle: 'Track a count-up or countdown streak',
                  onTap: () => context.push(AppRoutes.streak),
                ),
                const Divider(height: 1, indent: AppSpacing.base, endIndent: AppSpacing.base),
                _MovementToggleTile(state: state, controller: controller),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PetHeroCard extends StatelessWidget {
  const _PetHeroCard({required this.state, required this.controller});

  final OverlayUiState state;
  final OverlayController controller;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final (statusLabel, statusTone) = switch (state.status) {
      OverlayStatus.running => ('Active', AppStatusTone.success),
      OverlayStatus.starting => ('Starting…', AppStatusTone.warning),
      OverlayStatus.stopped => ('Stopped', AppStatusTone.neutral),
    };

    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl, horizontal: AppSpacing.xl),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.base),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [colorScheme.primary.withValues(alpha: 0.16), colorScheme.primary.withValues(alpha: 0.0)],
              ),
            ),
            child: PetAvatar(pet: state.selectedPet, size: 140, opacity: state.settings.opacity),
          ),
          const SizedBox(height: AppSpacing.base),
          Text(state.selectedPet.name, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          AppStatusChip(label: statusLabel, tone: statusTone),
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label: state.isRunning ? 'Stop floating pet' : 'Start floating pet',
            icon: state.isRunning ? Icons.stop_circle_outlined : Icons.play_circle_outline,
            isLoading: state.status == OverlayStatus.starting,
            onPressed: () => state.isRunning ? controller.stopOverlay() : controller.startOverlay(),
          ),
        ],
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({required this.icon, required this.title, required this.subtitle, required this.onTap});

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      onTap: onTap,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(color: colorScheme.primaryContainer, borderRadius: AppRadius.mdRadius),
        child: Icon(icon, color: colorScheme.primary, size: 20),
      ),
      title: Text(title),
      subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: Icon(Icons.chevron_right_rounded, color: colorScheme.onSurfaceVariant),
    );
  }
}

class _MovementToggleTile extends StatelessWidget {
  const _MovementToggleTile({required this.state, required this.controller});

  final OverlayUiState state;
  final OverlayController controller;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SwitchListTile(
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      secondary: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(color: colorScheme.primaryContainer, borderRadius: AppRadius.mdRadius),
        child: Icon(Icons.open_with_rounded, color: colorScheme.primary, size: 20),
      ),
      title: const Text('Automatic movement'),
      value: state.settings.movementEnabled,
      onChanged: (value) => controller.updateSettings((s) => s.copyWith(movementEnabled: value)),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.onPressed, this.tooltip});

  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip ?? '',
      child: InkWell(
        borderRadius: AppRadius.pillRadius,
        onTap: onPressed,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: colorScheme.primaryContainer, shape: BoxShape.circle),
          child: Icon(icon, color: colorScheme.primary, size: 20),
        ),
      ),
    );
  }
}
