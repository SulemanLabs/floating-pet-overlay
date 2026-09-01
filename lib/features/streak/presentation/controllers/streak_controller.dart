import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failures.dart';
import '../../../overlay/presentation/providers/overlay_providers.dart';
import '../../domain/entities/streak_entity.dart';
import '../providers/streak_providers.dart';
import 'streak_controller_state.dart';

/// Single authoritative streak controller: Hive is the persisted source of
/// truth, this loads it into Riverpod state, and pushes the current/terminal
/// streak to the native overlay. Neither the UI nor the overlay maintain any
/// independent streak state of their own.
class StreakController extends AsyncNotifier<StreakControllerState> {
  @override
  Future<StreakControllerState> build() async {
    // Must run on every cold start — a timed streak's deadline may have
    // passed while the app wasn't running at all.
    await ref.read(checkStreakExpirationProvider).call();
    return _loadState();
  }

  Future<StreakControllerState> _loadState() async {
    final current = await ref.read(getCurrentStreakProvider).call();
    final history = await ref.read(getStreakHistoryProvider).call();
    final stats = await ref.read(getStreakStatsProvider).call();
    await _syncCurrentToOverlay(current);
    return StreakControllerState(current: current, history: history, stats: stats);
  }

  Future<void> start({Duration? duration}) async {
    try {
      await ref.read(startStreakProvider).call(duration: duration);
      state = AsyncData(await _loadState());
    } on Failure catch (e) {
      _setError(e.message);
    }
  }

  /// Manually completes the active streak (the "Complete Streak" action for
  /// an open-ended streak).
  Future<void> completeCurrent() async {
    final id = state.value?.current?.id;
    if (id == null) return;
    try {
      final resolved = await ref.read(completeStreakProvider).call(id);
      await _syncTerminalToOverlay(resolved);
      state = AsyncData(await _loadState());
    } on Failure catch (e) {
      _setError(e.message);
    }
  }

  Future<void> breakCurrent() async {
    final id = state.value?.current?.id;
    if (id == null) return;
    try {
      final resolved = await ref.read(breakStreakProvider).call(id);
      await _syncTerminalToOverlay(resolved);
      state = AsyncData(await _loadState());
    } on Failure catch (e) {
      _setError(e.message);
    }
  }

  Future<void> delete(String streakId) async {
    await ref.read(deleteStreakProvider).call(streakId);
    state = AsyncData(await _loadState());
  }

  Future<void> refresh() async {
    state = AsyncData(await _loadState());
  }

  /// Must run on startup and on every app resume (see `_AppLifecycleGate` in
  /// `app.dart`) — never relies on a background timer to catch an expired
  /// timed streak while the app wasn't in the foreground.
  Future<void> checkExpiration() async {
    final completed = await ref.read(checkStreakExpirationProvider).call();
    if (completed != null) {
      await _syncTerminalToOverlay(completed);
      state = AsyncData(await _loadState());
    }
  }

  Future<void> handleAppResumed() async {
    await checkExpiration();
    await refresh();
  }

  void clearError() {
    final current = state.value;
    if (current != null) state = AsyncData(current.copyWith(clearError: true));
  }

  void _setError(String message) {
    final current = state.value;
    if (current != null) state = AsyncData(current.copyWith(errorMessage: message));
  }

  /// Reflects ground truth: an active streak's live state, or clears the
  /// badge if nothing is active. Called after every load/refresh.
  Future<void> _syncCurrentToOverlay(StreakEntity? current) async {
    try {
      final overlay = ref.read(overlayRepositoryProvider);
      if (current == null) {
        await overlay.clearStreak();
      } else {
        await overlay.syncStreak(
          mode: current.isOpenEnded ? 'count_up' : 'countdown',
          status: current.status.name,
          startDate: current.startDate,
          endDate: current.endDate,
        );
      }
    } on Failure catch (_) {
      // Overlay unavailable/permission missing must never break streak
      // persistence or in-app functionality (spec §34/§39).
    }
  }

  /// Pushes a just-resolved (completed/broken) streak's terminal status so
  /// the native overlay can show its brief "Streak Complete"/"Streak Broken"
  /// message before self-clearing — see `StreakTicker.kt`. Intentionally
  /// distinct from [_syncCurrentToOverlay], which would clear the badge
  /// immediately instead of letting that transient message show.
  Future<void> _syncTerminalToOverlay(StreakEntity resolved) async {
    try {
      await ref.read(overlayRepositoryProvider).syncStreak(
        mode: resolved.isOpenEnded ? 'count_up' : 'countdown',
        status: resolved.status.name,
        startDate: resolved.startDate,
        endDate: resolved.endDate,
      );
    } on Failure catch (_) {
      // Same rationale as above.
    }
  }
}
