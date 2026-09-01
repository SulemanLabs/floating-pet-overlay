import '../entities/streak_entity.dart';
import '../repositories/streak_repository.dart';

class GetStreakHistoryUseCase {
  const GetStreakHistoryUseCase(this._repository);

  final StreakRepository _repository;

  Future<List<StreakEntity>> call() => _repository.getStreakHistory();
}
