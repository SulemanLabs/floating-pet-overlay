import '../entities/streak_entity.dart';
import '../repositories/streak_repository.dart';

/// Must run on app startup and on every app resume (never relies on a
/// background timer to catch this). Detects a timed streak whose `endDate`
/// has passed and marks it completed with `completedAt == endDate`.
class CheckStreakExpirationUseCase {
  const CheckStreakExpirationUseCase(this._repository);

  final StreakRepository _repository;

  Future<StreakEntity?> call() => _repository.checkExpiration();
}
