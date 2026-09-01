import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../providers/overlay_providers.dart';

/// Explains why the "display over other apps" permission is required,
/// opens the system settings page, and re-checks permission when the user
/// returns to the app (Android never notifies the app directly — polling
/// `onResume` is the standard pattern for this permission).
class OverlayPermissionScreen extends ConsumerStatefulWidget {
  const OverlayPermissionScreen({super.key});

  @override
  ConsumerState<OverlayPermissionScreen> createState() => _OverlayPermissionScreenState();
}

class _OverlayPermissionScreenState extends ConsumerState<OverlayPermissionScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(overlayControllerProvider.notifier).refreshPermissions();
    }
  }

  @override
  Widget build(BuildContext context) {
    final overlayAsync = ref.watch(overlayControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Overlay permission')),
      body: overlayAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('$error')),
        data: (state) {
          final controller = ref.read(overlayControllerProvider.notifier);
          final granted = state.overlayPermissionGranted;
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final accent = granted ? (isDark ? AppColors.darkSuccess : AppColors.success) : Theme.of(context).colorScheme.primary;

          return Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                Center(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.85, end: 1),
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeOutBack,
                    builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
                    child: Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [accent.withValues(alpha: 0.18), accent.withValues(alpha: 0.0)],
                        ),
                      ),
                      child: Icon(
                        granted ? Icons.check_circle_rounded : Icons.layers_rounded,
                        size: 88,
                        color: accent,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  granted ? 'Permission granted' : 'Display over other apps',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.base),
                Text(
                  granted
                      ? 'Your pet can now float above other apps. You can start it from the home screen.'
                      : 'Floating Pet Overlay needs the "display over other apps" permission to draw your '
                          'pet above other applications. This is what lets the pet keep moving and follow '
                          'your finger even while you use other apps.\n\n'
                          'Tap below to open system settings, enable the permission for this app, then '
                          'return here.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const Spacer(),
                if (!granted)
                  AppButton(label: 'Open settings', onPressed: controller.requestOverlayPermission)
                else
                  AppButton(label: 'Continue', onPressed: () => Navigator.of(context).maybePop()),
                if (!state.notificationPermissionGranted) ...[
                  const SizedBox(height: AppSpacing.md),
                  AppButton(
                    label: 'Allow notifications',
                    variant: AppButtonVariant.secondary,
                    onPressed: controller.requestNotificationPermission,
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
