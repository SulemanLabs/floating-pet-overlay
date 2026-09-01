import '../entities/streak_entity.dart';
import '../entities/streak_stats.dart';

/// Isolates the rest of the app from Hive — see `StreakRepositoryImpl` for
/// the actual box access and `StreakLocalDataSource` for the raw storage
/// calls. Entity construction (id/timestamps) is a use-case concern, not a
/// repository one, matching `TaskRepository.addTask` taking a full entity.
abstract class StreakRepository {
  Future<StreakEntity?> getCurrentStreak();

  Future<List<StreakEntity>> getStreakHistory();

  /// Persists an already-constructed active streak. Callers (use cases) are
  /// responsible for the duplicate-active-streak check before calling this.
  Future<void> startStreak(StreakEntity streak);

  /// Marks the given streak completed "now" (`completedAt = DateTime.now()`)
  /// — used for manual completion of an open-ended streak. A timed streak's
  /// natural completion goes through [checkExpiration] instead, which sets
  /// `completedAt = endDate`. Returns the resolved streak so the caller can
  /// push its terminal status to the overlay before clearing it.
  Future<StreakEntity> completeStreak(String streakId);

  Future<StreakEntity> breakStreak(String streakId);

  /// Checks the current active streak (if any) for a timed streak whose
  /// `endDate` has passed, and if so marks it completed with
  /// `completedAt == endDate`. Returns the newly-completed streak, or `null`
  /// if nothing changed.
  Future<StreakEntity?> checkExpiration();

  Future<void> deleteStreak(String streakId);

  Future<StreakStats> getStats();
}
