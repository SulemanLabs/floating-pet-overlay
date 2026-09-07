import '../../../../core/constants/app_constants.dart';
import '../../../../core/storage/local_storage.dart';

/// Persists the one-time "has the user finished onboarding" flag. A single
/// boolean doesn't warrant a repository/entity layer of its own — the
/// datasource is the whole feature's data layer.
class OnboardingLocalDataSource {
  OnboardingLocalDataSource(this._storage);

  final LocalStorage _storage;

  bool isCompleted() => _storage.getBool(AppConstants.onboardingCompletedKey) ?? false;

  Future<void> markCompleted() => _storage.setBool(AppConstants.onboardingCompletedKey, true);
}
