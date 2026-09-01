import '../entities/streak_entity.dart';
import '../repositories/streak_repository.dart';

/// Manually completes an active streak (the open-ended "Complete Streak"
/// action). `completedAt` is stamped as `DateTime.now()` by the repository.
class CompleteStreakUseCase {
  const CompleteStreakUseCase(this._repository);

  final StreakRepository _repository;

  Future<StreakEntity> call(String streakId) => _repository.completeStreak(streakId);
}
