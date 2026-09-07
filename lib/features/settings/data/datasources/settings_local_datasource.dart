import '../../../../core/constants/app_constants.dart';
import '../../../../core/storage/local_storage.dart';
import '../../domain/entities/overlay_settings.dart';

class SettingsLocalDataSource {
  SettingsLocalDataSource(this._storage);

  final LocalStorage _storage;

  static const _sizeKey = 'settings.size_percent';
  static const _opacityKey = 'settings.opacity';
  static const _speedKey = 'settings.speed';
  static const _movementKey = 'settings.movement_enabled';
  static const _autoStartKey = 'settings.auto_start_enabled';

  OverlaySettings read() {
    return OverlaySettings(
      sizePercent: _storage.getDouble(_sizeKey) ?? AppConstants.defaultSizePercent,
      opacity: _storage.getDouble(_opacityKey) ?? AppConstants.defaultOpacity,
      speed: _storage.getDouble(_speedKey) ?? AppConstants.defaultSpeed,
      movementEnabled: _storage.getBool(_movementKey) ?? AppConstants.defaultMovementEnabled,
      autoStartEnabled: _storage.getBool(_autoStartKey) ?? AppConstants.defaultAutoStartEnabled,
    );
  }

  Future<void> write(OverlaySettings settings) async {
    await _storage.setDouble(_sizeKey, settings.sizePercent);
    await _storage.setDouble(_opacityKey, settings.opacity);
    await _storage.setDouble(_speedKey, settings.speed);
    await _storage.setBool(_movementKey, settings.movementEnabled);
    await _storage.setBool(_autoStartKey, settings.autoStartEnabled);
  }
}
