import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../features/pets/data/models/pet_model.dart';
import '../../features/streak/data/models/streak_model.dart';
import '../../features/tasks/data/models/task_model.dart';
import '../crash_reporting/crash_reporting_service.dart';
import '../platform/overlay_platform_bridge.dart';
import '../storage/local_storage.dart';

/// Overridden in `main.dart` with the instance created during app startup
/// (see `LocalStorage.create()`), so every other provider can read it
/// synchronously instead of every screen juggling a `FutureProvider`.
final localStorageProvider = Provider<LocalStorage>((ref) {
  throw UnimplementedError('localStorageProvider must be overridden in main() before runApp');
});

/// Overridden in `main.dart` with the `streaks` box opened during app
/// startup — same bootstrap shape as [localStorageProvider], so the streak
/// feature's providers can read it synchronously.
final streakHiveBoxProvider = Provider<Box<StreakModel>>((ref) {
  throw UnimplementedError('streakHiveBoxProvider must be overridden in main() before runApp');
});

/// Overridden in `main.dart` with the `tasks` box opened during app startup.
final taskHiveBoxProvider = Provider<Box<TaskModel>>((ref) {
  throw UnimplementedError('taskHiveBoxProvider must be overridden in main() before runApp');
});

/// Overridden in `main.dart` with the `pets` box opened during app startup.
final petHiveBoxProvider = Provider<Box<PetModel>>((ref) {
  throw UnimplementedError('petHiveBoxProvider must be overridden in main() before runApp');
});

final overlayPlatformBridgeProvider = Provider<OverlayPlatformBridge>((ref) {
  final bridge = OverlayPlatformBridge();
  ref.onDispose(bridge.dispose);
  return bridge;
});

/// Overridden in `main.dart` with the instance created during app startup
/// (global error handlers must be wired before anything else can crash) —
/// same bootstrap shape as [localStorageProvider].
final crashReportingServiceProvider = Provider<CrashReportingService>((ref) {
  throw UnimplementedError('crashReportingServiceProvider must be overridden in main() before runApp');
});
