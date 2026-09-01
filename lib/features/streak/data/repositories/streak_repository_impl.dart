import '../../../../core/errors/failures.dart';
import '../../domain/entities/streak_entity.dart';
import '../../domain/entities/streak_stats.dart';
import '../../domain/repositories/streak_repository.dart';
import '../datasources/streak_local_datasource.dart';
import '../models/streak_model.dart';

class StreakRepositoryImpl implements StreakRepository {
  StreakRepositoryImpl(this._localDataSource);

  final StreakLocalDataSource _localDataSource;

  @override
  Future<StreakEntity?> getCurrentStreak() async {
    final models = _localDataSource.getAll();
    for (final model in models) {
      if (model.statusIndex == StreakStatus.active.index) return model.toEntity();
    }
    return null;
  }

  @override
  Future<List<StreakEntity>> getStreakHistory() async {
    final entities = _localDataSource.getAll().map((m) => m.toEntity()).toList();
    entities.sort((a, b) => b.startDate.compareTo(a.startDate));
    return entities;
  }

  @override
  Future<void> startStreak(StreakEntity streak) async {
    await _localDataSource.put(StreakModel.fromEntity(streak));
  }

  @override
  Future<StreakEntity> completeStreak(String streakId) async {
    final model = _localDataSource.getById(streakId);
    if (model == null) throw const StreakValidationFailure('That streak no longer exists.');
    final updated = model.toEntity().copyWith(status: StreakStatus.completed, completedAt: DateTime.now());
    await _localDataSource.put(StreakModel.fromEntity(updated));
    return updated;
  }

  @override
  Future<StreakEntity> breakStreak(String streakId) async {
    final model = _localDataSource.getById(streakId);
    if (model == null) throw const StreakValidationFailure('That streak no longer exists.');
    final updated = model.toEntity().copyWith(status: StreakStatus.broken, brokenAt: DateTime.now());
    await _localDataSource.put(StreakModel.fromEntity(updated));
    return updated;
  }

  @override
  Future<StreakEntity?> checkExpiration() async {
    final current = await getCurrentStreak();
    if (current == null || current.isOpenEnded) return null;

    final endDate = current.endDate!;
    if (!DateTime.now().isBefore(endDate)) {
      final completed = current.copyWith(status: StreakStatus.completed, completedAt: endDate);
      await _localDataSource.put(StreakModel.fromEntity(completed));
      return completed;
    }
    return null;
  }

  @override
  Future<void> deleteStreak(String streakId) async {
    await _localDataSource.delete(streakId);
  }

  @override
  Future<StreakStats> getStats() async {
    final history = await getStreakHistory();
    final current = history.where((s) => s.isActive).firstOrNull;
    final resolved = history.where((s) => !s.isActive);

    final completed = resolved.where((s) => s.isCompleted).length;
    final broken = resolved.where((s) => s.isBroken).length;
    final denominator = completed + broken;

    var longest = Duration.zero;
    for (final streak in resolved) {
      if (streak.actualDuration > longest) longest = streak.actualDuration;
    }

    return StreakStats(
      totalStreaks: history.length,
      completedStreaks: completed,
      brokenStreaks: broken,
      currentStreak: current?.elapsed,
      longestStreak: longest,
      successRate: denominator == 0 ? 0 : (completed / denominator) * 100,
    );
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
