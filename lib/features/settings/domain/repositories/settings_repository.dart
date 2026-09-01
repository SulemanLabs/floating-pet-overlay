import '../entities/overlay_settings.dart';

abstract class SettingsRepository {
  Future<OverlaySettings> getSettings();

  Future<void> saveSettings(OverlaySettings settings);
}
