import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_section_header.dart';
import '../../../overlay/presentation/providers/overlay_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overlayAsync = ref.watch(overlayControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: overlayAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('$error')),
        data: (state) {
          final controller = ref.read(overlayControllerProvider.notifier);
          final settings = state.settings;

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.base),
            children: [
              const AppSectionHeader('Appearance'),
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    ListTile(
                      title: const Text('Size'),
                      subtitle: Slider(
                        value: settings.sizePercent,
                        min: 0.5,
                        max: 2.0,
                        divisions: 6,
                        label: '${(settings.sizePercent * 100).round()}%',
                        onChanged: (value) => controller.updateSettings((s) => s.copyWith(sizePercent: value)),
                      ),
                      trailing: Text('${(settings.sizePercent * 100).round()}%'),
                    ),
                    const Divider(height: 1, indent: AppSpacing.base, endIndent: AppSpacing.base),
                    ListTile(
                      title: const Text('Opacity'),
                      subtitle: Slider(
                        value: settings.opacity,
                        min: 0.1,
                        max: 1.0,
                        divisions: 9,
                        label: '${(settings.opacity * 100).round()}%',
                        onChanged: (value) => controller.updateSettings((s) => s.copyWith(opacity: value)),
                      ),
                      trailing: Text('${(settings.opacity * 100).round()}%'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              const AppSectionHeader('Movement'),
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Enable movement'),
                      subtitle: const Text('Let the pet wander and bounce off screen edges'),
                      value: settings.movementEnabled,
                      onChanged: (value) => controller.updateSettings((s) => s.copyWith(movementEnabled: value)),
                    ),
                    const Divider(height: 1, indent: AppSpacing.base, endIndent: AppSpacing.base),
                    ListTile(
                      title: const Text('Movement speed'),
                      subtitle: Slider(
                        value: settings.speed,
                        min: 0.0,
                        max: 1.0,
                        divisions: 4,
                        label: _speedLabel(settings.speed),
                        onChanged: settings.movementEnabled
                            ? (value) => controller.updateSettings((s) => s.copyWith(speed: value))
                            : null,
                      ),
                      trailing: Text(_speedLabel(settings.speed)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              const AppSectionHeader('Behavior'),
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Sounds'),
                      subtitle: const Text('Play sounds for pet reactions'),
                      value: settings.soundEnabled,
                      onChanged: (value) => controller.updateSettings((s) => s.copyWith(soundEnabled: value)),
                    ),
                    const Divider(height: 1, indent: AppSpacing.base, endIndent: AppSpacing.base),
                    SwitchListTile(
                      title: const Text('Start automatically'),
                      subtitle: const Text('Launch the floating pet when the device boots'),
                      value: settings.autoStartEnabled,
                      onChanged: (value) => controller.updateSettings((s) => s.copyWith(autoStartEnabled: value)),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  static String _speedLabel(double speed) {
    if (speed < 0.2) return 'Very slow';
    if (speed < 0.4) return 'Slow';
    if (speed < 0.6) return 'Normal';
    if (speed < 0.8) return 'Fast';
    return 'Very fast';
  }
}
