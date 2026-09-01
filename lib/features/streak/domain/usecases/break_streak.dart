import '../entities/streak_entity.dart';
import '../repositories/streak_repository.dart';

class BreakStreakUseCase {
  const BreakStreakUseCase(this._repository);

  final StreakRepository _repository;

  Future<StreakEntity> call(String streakId) => _repository.breakStreak(streakId);
}
