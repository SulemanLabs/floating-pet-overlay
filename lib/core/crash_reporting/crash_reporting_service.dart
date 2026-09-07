import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Crash/error reporting, abstracted the same way `OverlayRepository` sits
/// in front of `OverlayPlatformBridge` — call sites depend on this
/// interface, never on [FirebaseCrashReportingService] directly, so tests
/// can supply a hand-written fake instead of exercising Firebase.
abstract class CrashReportingService {
  /// Records an error. [fatal] marks it as an app crash rather than a
  /// recovered/non-fatal error; [reason] adds free-text context visible in
  /// the Crashlytics dashboard.
  Future<void> recordError(Object error, StackTrace? stackTrace, {bool fatal = false, String? reason});
}

/// Real, Firebase-backed [CrashReportingService].
class FirebaseCrashReportingService implements CrashReportingService {
  FirebaseCrashReportingService._();

  /// Sets up global Flutter-framework and platform/async error handlers and
  /// toggles collection — off in debug builds, so local dev noise never
  /// reaches the dashboard; the handlers stay wired regardless, so a
  /// debug-build crash still surfaces in the console exactly as before.
  /// Must be called once during bootstrap, after `Firebase.initializeApp()`.
  static Future<FirebaseCrashReportingService> initialize() async {
    final service = FirebaseCrashReportingService._();

    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(!kDebugMode);
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stackTrace) {
      service.recordError(error, stackTrace, fatal: true);
      return true;
    };

    return service;
  }

  @override
  Future<void> recordError(Object error, StackTrace? stackTrace, {bool fatal = false, String? reason}) {
    return FirebaseCrashlytics.instance.recordError(error, stackTrace, fatal: fatal, reason: reason);
  }

  /// Best-effort record for the narrow bootstrap window before [initialize]
  /// has run — including when it's what failed. Swallows any secondary
  /// failure so reporting itself never masks the original error from the
  /// app's startup-failure recovery screen.
  static Future<void> recordBestEffort(Object error, StackTrace stackTrace) async {
    try {
      await FirebaseCrashlytics.instance.recordError(error, stackTrace, fatal: true);
    } catch (_) {
      // Ignored — see above.
    }
  }
}
