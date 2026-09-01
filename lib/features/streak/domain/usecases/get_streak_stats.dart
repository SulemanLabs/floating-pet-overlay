import '../entities/streak_stats.dart';
import '../repositories/streak_repository.dart';

class GetStreakStatsUseCase {
  const GetStreakStatsUseCase(this._repository);

  final StreakRepository _repository;

  Future<StreakStats> call() => _repository.getStats();
}
