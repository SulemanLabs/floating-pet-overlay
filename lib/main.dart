import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'core/crash_reporting/crash_reporting_service.dart';
import 'core/providers/core_providers.dart';
import 'core/storage/local_storage.dart';
import 'features/pets/data/models/pet_model.dart';
import 'features/streak/data/models/streak_model.dart';
import 'features/tasks/data/models/task_model.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _bootstrap();
}

/// Runs the full startup sequence and swaps in the real app on success. On
/// failure it shows a retry screen instead of leaving the native splash
/// screen stuck forever with no way to recover short of a force-stop.
Future<void> _bootstrap() async {
  try {
    // Reads android/app/google-services.json (processed at build time by the
    // google-services Gradle plugin) — no FlutterFire-generated options file
    // needed for this Android-only build.
    await Firebase.initializeApp();
    // Must be awaited exactly once, before any other GoogleSignIn.instance
    // call (see LoginScreen / auth_remote_datasource.dart).
    await GoogleSignIn.instance.initialize();

    // From here on, every uncaught error — Flutter framework and
    // platform/async alike — is reported to Crashlytics (see
    // `FirebaseCrashReportingService.initialize`).
    final crashReporting = await FirebaseCrashReportingService.initialize();

    await Hive.initFlutter();
    _registerAdapters();

    // Each `_openBox` call starts running immediately (an async function
    // body runs synchronously up to its first `await`), so kicking all four
    // off before awaiting any of them opens the boxes concurrently rather
    // than waiting out each one's retry backoff in turn.
    final prefsFuture = _openBox('prefs');
    final streakFuture = _openBox<StreakModel>('streaks');
    final taskFuture = _openBox<TaskModel>('tasks');
    final petFuture = _openBox<PetModel>('pets');

    final localStorage = LocalStorage(await prefsFuture);
    final streakBox = await streakFuture;
    final taskBox = await taskFuture;
    final petBox = await petFuture;

    runApp(
      ProviderScope(
        overrides: [
          localStorageProvider.overrideWithValue(localStorage),
          streakHiveBoxProvider.overrideWithValue(streakBox),
          taskHiveBoxProvider.overrideWithValue(taskBox),
          petHiveBoxProvider.overrideWithValue(petBox),
          crashReportingServiceProvider.overrideWithValue(crashReporting),
        ],
        child: const FloatingPetOverlayApp(),
      ),
    );
  } catch (error, stackTrace) {
    // Best-effort: `FirebaseCrashReportingService.initialize()` may not
    // have run yet (e.g. this is the very `Firebase.initializeApp()`
    // failure that would have broken it), so this goes straight to the
    // static fallback rather than a provider that may not exist.
    await FirebaseCrashReportingService.recordBestEffort(error, stackTrace);
    runApp(_BootstrapErrorApp(error: error, onRetry: _bootstrap));
  }
}

/// Idempotent so re-running `main()` within the same process (as tests that
/// don't fully isolate Hive's global state can do) never double-registers an
/// adapter.
void _registerAdapters() {
  if (!Hive.isAdapterRegistered(streakModelTypeId)) {
    Hive.registerAdapter(StreakModelAdapter());
  }
  if (!Hive.isAdapterRegistered(taskModelTypeId)) {
    Hive.registerAdapter(TaskModelAdapter());
  }
  if (!Hive.isAdapterRegistered(petModelTypeId)) {
    Hive.registerAdapter(PetModelAdapter());
  }
}

/// The overlay can relaunch `MainActivity` — and with it a brand-new Flutter
/// engine/isolate that re-runs this whole `main()` — while the *previous*
/// engine's isolate is still tearing down (the OS process itself survives,
/// kept alive by `OverlayService`'s foreground service, so the old isolate's
/// file locks don't get force-released the way a full process kill would).
/// `Hive.close()` is never called on that shutdown path, so the old isolate
/// can still be holding the file lock on a box's file for a bit. Retry with
/// a generous backoff — opening 4 boxes instead of 1 means 4 independent
/// chances to lose this race, so the window needs real headroom — rather
/// than letting it take down the whole app.
Future<Box<T>> _openBox<T>(String name) async {
  if (Hive.isBoxOpen(name)) {
    return Hive.box<T>(name);
  }
  const maxAttempts = 20;
  for (var attempt = 1; ; attempt++) {
    try {
      return await Hive.openBox<T>(name);
    } catch (_) {
      if (attempt >= maxAttempts) rethrow;
      await Future.delayed(Duration(milliseconds: (200 * attempt).clamp(0, 1000)));
    }
  }
}

class _BootstrapErrorApp extends StatelessWidget {
  const _BootstrapErrorApp({required this.error, required this.onRetry});

  final Object error;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded, size: 56),
                const SizedBox(height: 16),
                const Text('Floating Streak couldn\'t start', textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text(error.toString(), textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 24),
                FilledButton(onPressed: onRetry, child: const Text('Retry')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
