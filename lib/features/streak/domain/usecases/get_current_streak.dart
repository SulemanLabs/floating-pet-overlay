import '../entities/streak_entity.dart';
import '../repositories/streak_repository.dart';

class GetCurrentStreakUseCase {
  const GetCurrentStreakUseCase(this._repository);

  final StreakRepository _repository;

  Future<StreakEntity?> call() => _repository.getCurrentStreak();
}
