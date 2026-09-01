import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../features/streak/data/models/streak_model.dart';
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

final overlayPlatformBridgeProvider = Provider<OverlayPlatformBridge>((ref) {
  final bridge = OverlayPlatformBridge();
  ref.onDispose(bridge.dispose);
  return bridge;
});
