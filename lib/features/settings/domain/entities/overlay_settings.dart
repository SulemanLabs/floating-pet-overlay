import '../../../../core/constants/app_constants.dart';

/// User-configurable overlay behavior. Kept separate from [PetEntity] since
/// settings apply regardless of which pet is active.
class OverlaySettings {
  const OverlaySettings({
    this.sizePercent = AppConstants.defaultSizePercent,
    this.opacity = AppConstants.defaultOpacity,
    this.speed = AppConstants.defaultSpeed,
    this.movementEnabled = AppConstants.defaultMovementEnabled,
    this.autoStartEnabled = AppConstants.defaultAutoStartEnabled,
  });

  final double sizePercent;
  final double opacity;
  final double speed;
  final bool movementEnabled;
  final bool autoStartEnabled;

  OverlaySettings copyWith({
    double? sizePercent,
    double? opacity,
    double? speed,
    bool? movementEnabled,
    bool? autoStartEnabled,
  }) {
    return OverlaySettings(
      sizePercent: _clamp(sizePercent ?? this.sizePercent, AppConstants.minSizePercent, AppConstants.maxSizePercent),
      opacity: _clamp(opacity ?? this.opacity, AppConstants.minOpacity, AppConstants.maxOpacity),
      speed: _clamp(speed ?? this.speed, AppConstants.minSpeed, AppConstants.maxSpeed),
      movementEnabled: movementEnabled ?? this.movementEnabled,
      autoStartEnabled: autoStartEnabled ?? this.autoStartEnabled,
    );
  }

  static double _clamp(double value, double min, double max) => value.clamp(min, max).toDouble();
}
