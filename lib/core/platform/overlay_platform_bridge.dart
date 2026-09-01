import 'dart:async';

import 'package:flutter/services.dart';

import '../constants/platform_channel_constants.dart';
import '../errors/failures.dart';
import 'overlay_platform_events.dart';

/// Sole owner of the `MethodChannel` that talks to the Android side.
///
/// Every other layer (repositories, providers) goes through this class
/// rather than touching `MethodChannel` directly, so the platform boundary
/// stays in one place and is easy to fake in tests.
class OverlayPlatformBridge {
  OverlayPlatformBridge({MethodChannel? channel})
      : _channel = channel ?? const MethodChannel(PlatformChannelConstants.controlChannel) {
    _channel.setMethodCallHandler(_handleNativeCall);
  }

  final MethodChannel _channel;
  final StreamController<OverlayPlatformEvent> _eventController =
      StreamController<OverlayPlatformEvent>.broadcast();

  Stream<OverlayPlatformEvent> get events => _eventController.stream;

  Future<dynamic> _handleNativeCall(MethodCall call) async {
    switch (call.method) {
      case PlatformChannelConstants.eventOverlayStarted:
        _eventController.add(const OverlayStartedEvent());
      case PlatformChannelConstants.eventOverlayStopped:
        _eventController.add(const OverlayStoppedEvent());
      case PlatformChannelConstants.eventPetTapped:
        _eventController.add(const PetTappedEvent());
      case PlatformChannelConstants.eventPetDoubleTapped:
        _eventController.add(const PetDoubleTappedEvent());
      case PlatformChannelConstants.eventPermissionChanged:
        final args = Map<String, dynamic>.from(call.arguments as Map);
        _eventController.add(PermissionChangedEvent(args[PlatformChannelConstants.argGranted] as bool? ?? false));
      case PlatformChannelConstants.eventOverlayError:
        final args = Map<String, dynamic>.from(call.arguments as Map);
        _eventController.add(
          OverlayErrorEvent(args[PlatformChannelConstants.argMessage] as String? ?? 'Unknown overlay error'),
        );
      default:
        // Unknown call from a future native version — ignore rather than throw.
        break;
    }
    return null;
  }

  Future<T> _invoke<T>(String method, [Map<String, dynamic>? args]) async {
    try {
      final result = await _channel.invokeMethod<T>(method, args);
      if (result == null) {
        throw PlatformBridgeFailure('$method returned no result');
      }
      return result;
    } on PlatformException catch (e) {
      throw PlatformBridgeFailure(e.message ?? 'Platform call "$method" failed');
    } on MissingPluginException {
      throw const PlatformBridgeFailure('Overlay platform channel is not available on this platform');
    }
  }

  Future<bool> startOverlay({
    required String petType,
    String? petEmoji,
    String? petAssetPath,
    required double sizePercent,
    required double opacity,
    required double speed,
    required bool movementEnabled,
  }) {
    return _invoke<bool>(PlatformChannelConstants.methodStartOverlay, {
      PlatformChannelConstants.argPetType: petType,
      PlatformChannelConstants.argPetEmoji: petEmoji,
      PlatformChannelConstants.argPetAssetPath: petAssetPath,
      PlatformChannelConstants.argSizePercent: sizePercent,
      PlatformChannelConstants.argOpacity: opacity,
      PlatformChannelConstants.argSpeed: speed,
      PlatformChannelConstants.argMovementEnabled: movementEnabled,
    });
  }

  Future<bool> stopOverlay() => _invoke<bool>(PlatformChannelConstants.methodStopOverlay);

  Future<bool> updatePet({required String petType, String? petEmoji, String? petAssetPath}) {
    return _invoke<bool>(PlatformChannelConstants.methodUpdatePet, {
      PlatformChannelConstants.argPetType: petType,
      PlatformChannelConstants.argPetEmoji: petEmoji,
      PlatformChannelConstants.argPetAssetPath: petAssetPath,
    });
  }

  Future<bool> updateSize(double sizePercent) {
    return _invoke<bool>(PlatformChannelConstants.methodUpdateSize, {
      PlatformChannelConstants.argSizePercent: sizePercent,
    });
  }

  Future<bool> updateOpacity(double opacity) {
    return _invoke<bool>(PlatformChannelConstants.methodUpdateOpacity, {
      PlatformChannelConstants.argOpacity: opacity,
    });
  }

  Future<bool> updateSpeed(double speed) {
    return _invoke<bool>(PlatformChannelConstants.methodUpdateSpeed, {
      PlatformChannelConstants.argSpeed: speed,
    });
  }

  Future<bool> setMovementEnabled(bool enabled) {
    return _invoke<bool>(PlatformChannelConstants.methodSetMovementEnabled, {
      PlatformChannelConstants.argMovementEnabled: enabled,
    });
  }

  /// Mirrors the full settings snapshot into native `SharedPreferences` so
  /// the boot-completed receiver can restart the overlay without a running
  /// Flutter engine. See `BootCompletedReceiver.kt`.
  Future<bool> syncSettings({
    required String petType,
    String? petEmoji,
    String? petAssetPath,
    required double sizePercent,
    required double opacity,
    required double speed,
    required bool movementEnabled,
    required bool autoStartEnabled,
  }) {
    return _invoke<bool>(PlatformChannelConstants.methodSyncSettings, {
      PlatformChannelConstants.argPetType: petType,
      PlatformChannelConstants.argPetEmoji: petEmoji,
      PlatformChannelConstants.argPetAssetPath: petAssetPath,
      PlatformChannelConstants.argSizePercent: sizePercent,
      PlatformChannelConstants.argOpacity: opacity,
      PlatformChannelConstants.argSpeed: speed,
      PlatformChannelConstants.argMovementEnabled: movementEnabled,
      PlatformChannelConstants.argAutoStartEnabled: autoStartEnabled,
    });
  }

  Future<void> requestOverlayPermission() => _invoke<bool>(PlatformChannelConstants.methodRequestOverlayPermission);

  Future<bool> isOverlayPermissionGranted() => _invoke<bool>(PlatformChannelConstants.methodIsOverlayPermissionGranted);

  Future<String> getOverlayStatus() => _invoke<String>(PlatformChannelConstants.methodGetOverlayStatus);

  /// Pushes the soonest incomplete task's deadline (or `null` to clear it) so
  /// the native overlay can show a countdown and swap to an urgency emoji as
  /// it approaches — see `DeadlineTicker.kt`. Always mirrored into native
  /// storage regardless of whether the overlay is running, exactly like
  /// [syncSettings], so a later restart or boot-restore picks it up.
  Future<bool> syncNextDeadline({int? deadlineEpochMillis}) {
    return _invoke<bool>(PlatformChannelConstants.methodSyncNextDeadline, {
      PlatformChannelConstants.argDeadlineMillis: deadlineEpochMillis,
    });
  }

  Future<bool> isNotificationPermissionGranted() =>
      _invoke<bool>(PlatformChannelConstants.methodIsNotificationPermissionGranted);

  /// Pushes the active streak's mode/status/timestamps so the native overlay
  /// can render its own badge (top pill, alongside the task deadline badge —
  /// see `StreakTicker.kt`) purely from timestamps, never a value Flutter has
  /// to keep re-sending every second. Always mirrored into native storage
  /// regardless of whether the overlay is running, same as [syncSettings]
  /// and [syncNextDeadline].
  Future<bool> updateStreak({
    required String mode,
    required String status,
    required int startMillis,
    int? endMillis,
  }) {
    return _invoke<bool>(PlatformChannelConstants.methodUpdateStreak, {
      PlatformChannelConstants.argStreakMode: mode,
      PlatformChannelConstants.argStreakStatus: status,
      PlatformChannelConstants.argStreakStartMillis: startMillis,
      PlatformChannelConstants.argStreakEndMillis: endMillis,
    });
  }

  Future<bool> clearStreak() => _invoke<bool>(PlatformChannelConstants.methodClearStreak);

  Future<bool> requestNotificationPermission() =>
      _invoke<bool>(PlatformChannelConstants.methodRequestNotificationPermission);

  void dispose() {
    _eventController.close();
  }
}
