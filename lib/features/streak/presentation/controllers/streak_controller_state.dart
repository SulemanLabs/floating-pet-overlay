import '../../domain/entities/streak_entity.dart';
import '../../domain/entities/streak_stats.dart';

class StreakControllerState {
  const StreakControllerState({required this.current, required this.history, required this.stats, this.errorMessage});

  final StreakEntity? current;
  final List<StreakEntity> history;
  final StreakStats stats;
  final String? errorMessage;

  bool get hasActiveStreak => current != null;

  StreakControllerState copyWith({
    StreakEntity? current,
    bool clearCurrent = false,
    List<StreakEntity>? history,
    StreakStats? stats,
    String? errorMessage,
    bool clearError = false,
  }) {
    return StreakControllerState(
      current: clearCurrent ? null : (current ?? this.current),
      history: history ?? this.history,
      stats: stats ?? this.stats,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
