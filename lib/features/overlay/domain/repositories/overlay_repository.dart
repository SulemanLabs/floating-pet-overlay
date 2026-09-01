import '../../../../core/platform/overlay_platform_events.dart';
import '../../../pets/domain/entities/pet_entity.dart';
import '../../../settings/domain/entities/overlay_settings.dart';

/// Isolates every other layer from the raw `MethodChannel` bridge —
/// see `OverlayPlatformBridge` for the actual channel calls, and
/// `OverlayRepositoryImpl` for how a [PetEntity] + [OverlaySettings] pair
/// gets translated into bridge arguments.
abstract class OverlayRepository {
  Future<bool> isOverlayPermissionGranted();

  Future<void> requestOverlayPermission();

  Future<bool> isNotificationPermissionGranted();

  Future<bool> requestNotificationPermission();

  Future<void> startOverlay({required PetEntity pet, required OverlaySettings settings});

  Future<void> stopOverlay();

  Future<void> updatePet(PetEntity pet);

  Future<void> updateSize(double sizePercent);

  Future<void> updateOpacity(double opacity);

  Future<void> updateSpeed(double speed);

  Future<void> setMovementEnabled(bool enabled);

  /// Mirrors pet + settings into native storage for boot auto-restore.
  Future<void> syncSettings({required PetEntity pet, required OverlaySettings settings});

  /// Pushes the soonest incomplete task's deadline so the overlay can show a
  /// countdown and react with an urgency emoji. Pass `null` when no task is
  /// active (clears the countdown/urgency display).
  Future<void> syncNextDeadline(DateTime? deadline);

  /// Pushes the active streak's mode/status/timestamps so the overlay can
  /// render its own badge purely from timestamps. Deliberately takes
  /// primitives rather than a `StreakEntity` — the overlay feature must stay
  /// decoupled from the streak feature's domain layer.
  Future<void> syncStreak({
    required String mode,
    required String status,
    required DateTime startDate,
    DateTime? endDate,
  });

  /// Clears the streak badge — called once there's no active streak.
  Future<void> clearStreak();

  Stream<OverlayPlatformEvent> get events;
}
