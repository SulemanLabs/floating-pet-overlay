import '../../domain/entities/overlay_settings.dart';
import '../../domain/repositories/settings_repository.dart';
import '../datasources/settings_local_datasource.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  SettingsRepositoryImpl(this._localDataSource);

  final SettingsLocalDataSource _localDataSource;

  @override
  Future<OverlaySettings> getSettings() async => _localDataSource.read();

  @override
  Future<void> saveSettings(OverlaySettings settings) => _localDataSource.write(settings);
}
