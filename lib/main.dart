import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'core/providers/core_providers.dart';
import 'core/storage/local_storage.dart';
import 'features/streak/data/models/streak_model.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final localStorage = await LocalStorage.create();
  final streakBox = await _openStreakBox();

  runApp(
    ProviderScope(
      overrides: [
        localStorageProvider.overrideWithValue(localStorage),
        streakHiveBoxProvider.overrideWithValue(streakBox),
      ],
      child: const FloatingPetOverlayApp(),
    ),
  );
}

/// Idempotent so re-running `main()` within the same process (as tests that
/// don't fully isolate Hive's global state can do) never double-registers
/// the adapter or reopens an already-open box.
///
/// The overlay can relaunch `MainActivity` — and with it a brand-new Flutter
/// engine/isolate that re-runs this whole `main()` — while the *previous*
/// engine's isolate is still tearing down. `Hive.close()` is never called on
/// that shutdown path, so the old isolate can still be holding the file lock
/// on `streaks.hive` for a brief moment. Opening it here would otherwise
/// throw before `runApp()` ever runs (blank white screen, then the isolate
/// dies), so retry with backoff instead of letting that one race take down
/// the whole app.
Future<Box<StreakModel>> _openStreakBox() async {
  await Hive.initFlutter();
  if (!Hive.isAdapterRegistered(streakModelTypeId)) {
    Hive.registerAdapter(StreakModelAdapter());
  }
  if (Hive.isBoxOpen('streaks')) {
    return Hive.box<StreakModel>('streaks');
  }
  const maxAttempts = 5;
  for (var attempt = 1; ; attempt++) {
    try {
      return await Hive.openBox<StreakModel>('streaks');
    } catch (_) {
      if (attempt >= maxAttempts) rethrow;
      await Future.delayed(Duration(milliseconds: 150 * attempt));
    }
  }
}
