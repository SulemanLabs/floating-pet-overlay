/// Aggregate streak statistics. Every field is computed from
/// [StreakEntity]-derived actual durations at read time — nothing here is
/// independently persisted, so it can never drift from the streak history.
///
/// [longestStreak] is computed from *actual duration* across completed and
/// broken streaks alike: a broken streak that ran for 30 days is still the
/// longest run the user sustained, so it counts. Only the still-active
/// streak (if any) is excluded, since its duration is still changing.
class StreakStats {
  const StreakStats({
    required this.totalStreaks,
    required this.completedStreaks,
    required this.brokenStreaks,
    required this.currentStreak,
    required this.longestStreak,
    required this.successRate,
  });

  final int totalStreaks;
  final int completedStreaks;
  final int brokenStreaks;

  /// Elapsed time of the currently active streak, or `null` if none.
  final Duration? currentStreak;

  final Duration longestStreak;

  /// `completed / (completed + broken) * 100`. Active streaks are excluded —
  /// only resolved streaks count toward success rate.
  final double successRate;

  static const empty = StreakStats(
    totalStreaks: 0,
    completedStreaks: 0,
    brokenStreaks: 0,
    currentStreak: null,
    longestStreak: Duration.zero,
    successRate: 0,
  );
}
