import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/streak_entity.dart';
import '../providers/streak_providers.dart';

/// A display-only snapshot for the live-ticking UI (current-streak card,
/// home card). [displayDuration] is recomputed from [streak]'s timestamps on
/// every tick — it is never itself incremented or decremented.
class StreakCountdownValue {
  const StreakCountdownValue({required this.streak, required this.displayDuration, required this.isCountUp});

  final StreakEntity streak;
  final Duration displayDuration;
  final bool isCountUp;
}

final streakCountdownProvider = NotifierProvider<StreakCountdownController, StreakCountdownValue?>(
  StreakCountdownController.new,
);

/// Drives the ~1/sec UI refresh for the active streak. There is exactly one
/// instance of this timer for the whole app (a single provider), it only
/// exists while a streak is active, and every tick recomputes from
/// [StreakEntity.elapsed]/[StreakEntity.remaining] rather than maintaining
/// its own counter — see spec §20/§44.
class StreakCountdownController extends Notifier<StreakCountdownValue?> {
  Timer? _timer;

  @override
  StreakCountdownValue? build() {
    final streak = ref.watch(currentStreakProvider);
    ref.onDispose(() => _timer?.cancel());

    if (streak == null || !streak.isActive) return null;

    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    return _computeValue(streak);
  }

  void _tick() {
    final streak = ref.read(currentStreakProvider);
    if (streak == null || !streak.isActive) {
      _timer?.cancel();
      state = null;
      return;
    }
    state = _computeValue(streak);
  }

  StreakCountdownValue _computeValue(StreakEntity streak) {
    return streak.isOpenEnded
        ? StreakCountdownValue(streak: streak, displayDuration: streak.elapsed, isCountUp: true)
        : StreakCountdownValue(streak: streak, displayDuration: streak.remaining ?? Duration.zero, isCountUp: false);
  }
}
