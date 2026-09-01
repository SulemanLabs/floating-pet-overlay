import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../data/datasources/streak_local_datasource.dart';
import '../../data/repositories/streak_repository_impl.dart';
import '../../domain/entities/streak_entity.dart';
import '../../domain/entities/streak_stats.dart';
import '../../domain/repositories/streak_repository.dart';
import '../../domain/usecases/break_streak.dart';
import '../../domain/usecases/check_streak_expiration.dart';
import '../../domain/usecases/complete_streak.dart';
import '../../domain/usecases/delete_streak.dart';
import '../../domain/usecases/get_current_streak.dart';
import '../../domain/usecases/get_streak_history.dart';
import '../../domain/usecases/get_streak_stats.dart';
import '../../domain/usecases/start_streak.dart';
import '../controllers/streak_controller.dart';
import '../controllers/streak_controller_state.dart';
import 'streak_filter.dart';

final streakLocalDataSourceProvider = Provider<StreakLocalDataSource>((ref) {
  return StreakLocalDataSource(ref.watch(streakHiveBoxProvider));
});

final streakRepositoryProvider = Provider<StreakRepository>((ref) {
  return StreakRepositoryImpl(ref.watch(streakLocalDataSourceProvider));
});

final startStreakProvider = Provider<StartStreakUseCase>((ref) => StartStreakUseCase(ref.watch(streakRepositoryProvider)));

final getCurrentStreakProvider = Provider<GetCurrentStreakUseCase>(
  (ref) => GetCurrentStreakUseCase(ref.watch(streakRepositoryProvider)),
);

final getStreakHistoryProvider = Provider<GetStreakHistoryUseCase>(
  (ref) => GetStreakHistoryUseCase(ref.watch(streakRepositoryProvider)),
);

final completeStreakProvider = Provider<CompleteStreakUseCase>(
  (ref) => CompleteStreakUseCase(ref.watch(streakRepositoryProvider)),
);

final breakStreakProvider = Provider<BreakStreakUseCase>((ref) => BreakStreakUseCase(ref.watch(streakRepositoryProvider)));

final checkStreakExpirationProvider = Provider<CheckStreakExpirationUseCase>(
  (ref) => CheckStreakExpirationUseCase(ref.watch(streakRepositoryProvider)),
);

final deleteStreakProvider = Provider<DeleteStreakUseCase>((ref) => DeleteStreakUseCase(ref.watch(streakRepositoryProvider)));

final getStreakStatsProvider = Provider<GetStreakStatsUseCase>(
  (ref) => GetStreakStatsUseCase(ref.watch(streakRepositoryProvider)),
);

final streakControllerProvider = AsyncNotifierProvider<StreakController, StreakControllerState>(StreakController.new);

/// Derived read-only views over the controller's `AsyncValue`, so widgets
/// that only need one slice (e.g. just the current streak) don't have to
/// unwrap the whole state themselves.
final currentStreakProvider = Provider<StreakEntity?>((ref) {
  return ref.watch(streakControllerProvider).value?.current;
});

final streakHistoryProvider = Provider<List<StreakEntity>>((ref) {
  return ref.watch(streakControllerProvider).value?.history ?? const [];
});

final streakStatsProvider = Provider<StreakStats>((ref) {
  return ref.watch(streakControllerProvider).value?.stats ?? StreakStats.empty;
});

final filteredStreakHistoryProvider = Provider<List<StreakEntity>>((ref) {
  final history = ref.watch(streakHistoryProvider);
  final filter = ref.watch(streakFilterProvider);
  return applyStreakFilter(history, filter);
});
