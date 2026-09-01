import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/app_constants.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/streak/presentation/providers/streak_providers.dart';

class FloatingPetOverlayApp extends StatelessWidget {
  const FloatingPetOverlayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return _StreakLifecycleGate(
      child: MaterialApp.router(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        routerConfig: appRouter,
      ),
    );
  }
}

/// Re-checks streak expiration and resyncs the overlay whenever the app
/// comes back to the foreground (spec §22/§44) — a timed streak's deadline
/// may have passed while the app was backgrounded/killed, and this is the
/// only reliable place to catch that (never a background timer).
class _StreakLifecycleGate extends ConsumerStatefulWidget {
  const _StreakLifecycleGate({required this.child});

  final Widget child;

  @override
  ConsumerState<_StreakLifecycleGate> createState() => _StreakLifecycleGateState();
}

class _StreakLifecycleGateState extends ConsumerState<_StreakLifecycleGate> with WidgetsBindingObserver {
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
      ref.read(streakControllerProvider.notifier).handleAppResumed();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
