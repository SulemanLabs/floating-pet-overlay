import '../repositories/streak_repository.dart';

class DeleteStreakUseCase {
  const DeleteStreakUseCase(this._repository);

  final StreakRepository _repository;

  Future<void> call(String streakId) => _repository.deleteStreak(streakId);
}
