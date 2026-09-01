import '../../../../core/platform/overlay_platform_bridge.dart';
import '../../../../core/platform/overlay_platform_events.dart';
import '../../../pets/domain/entities/pet_entity.dart';
import '../../../settings/domain/entities/overlay_settings.dart';
import '../../domain/repositories/overlay_repository.dart';

class OverlayRepositoryImpl implements OverlayRepository {
  OverlayRepositoryImpl(this._bridge);

  final OverlayPlatformBridge _bridge;

  @override
  Stream<OverlayPlatformEvent> get events => _bridge.events;

  @override
  Future<bool> isOverlayPermissionGranted() => _bridge.isOverlayPermissionGranted();

  @override
  Future<void> requestOverlayPermission() => _bridge.requestOverlayPermission();

  @override
  Future<bool> isNotificationPermissionGranted() => _bridge.isNotificationPermissionGranted();

  @override
  Future<bool> requestNotificationPermission() => _bridge.requestNotificationPermission();

  @override
  Future<void> startOverlay({required PetEntity pet, required OverlaySettings settings}) {
    return _bridge.startOverlay(
      petType: pet.type.name,
      petEmoji: pet.emoji,
      petAssetPath: pet.assetPath,
      sizePercent: settings.sizePercent,
      opacity: settings.opacity,
      speed: settings.speed,
      movementEnabled: settings.movementEnabled,
    );
  }

  @override
  Future<void> stopOverlay() => _bridge.stopOverlay();

  @override
  Future<void> updatePet(PetEntity pet) {
    return _bridge.updatePet(petType: pet.type.name, petEmoji: pet.emoji, petAssetPath: pet.assetPath);
  }

  @override
  Future<void> updateSize(double sizePercent) => _bridge.updateSize(sizePercent);

  @override
  Future<void> updateOpacity(double opacity) => _bridge.updateOpacity(opacity);

  @override
  Future<void> updateSpeed(double speed) => _bridge.updateSpeed(speed);

  @override
  Future<void> setMovementEnabled(bool enabled) => _bridge.setMovementEnabled(enabled);

  @override
  Future<void> syncSettings({required PetEntity pet, required OverlaySettings settings}) {
    return _bridge.syncSettings(
      petType: pet.type.name,
      petEmoji: pet.emoji,
      petAssetPath: pet.assetPath,
      sizePercent: settings.sizePercent,
      opacity: settings.opacity,
      speed: settings.speed,
      movementEnabled: settings.movementEnabled,
      autoStartEnabled: settings.autoStartEnabled,
    );
  }

  @override
  Future<void> syncNextDeadline(DateTime? deadline) {
    return _bridge.syncNextDeadline(deadlineEpochMillis: deadline?.millisecondsSinceEpoch);
  }

  @override
  Future<void> syncStreak({
    required String mode,
    required String status,
    required DateTime startDate,
    DateTime? endDate,
  }) {
    return _bridge.updateStreak(
      mode: mode,
      status: status,
      startMillis: startDate.millisecondsSinceEpoch,
      endMillis: endDate?.millisecondsSinceEpoch,
    );
  }

  @override
  Future<void> clearStreak() => _bridge.clearStreak();
}
