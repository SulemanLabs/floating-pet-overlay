enum StreakStatus { active, completed, broken }

/// A single streak run — either open-ended (count up, no [endDate]) or timed
/// (count down to [endDate]). All timing is derived from the timestamps
/// below at read time; nothing here is a persisted tick count, so the values
/// stay correct across app restarts, backgrounding, and device sleep.
class StreakEntity {
  const StreakEntity({
    required this.id,
    required this.startDate,
    this.endDate,
    this.duration,
    required this.status,
    this.completedAt,
    this.brokenAt,
  });

  final String id;
  final DateTime startDate;
  final DateTime? endDate;
  final Duration? duration;
  final StreakStatus status;
  final DateTime? completedAt;
  final DateTime? brokenAt;

  bool get isActive => status == StreakStatus.active;

  bool get isCompleted => status == StreakStatus.completed;

  bool get isBroken => status == StreakStatus.broken;

  bool get isOpenEnded => endDate == null;

  bool get isTimed => endDate != null;

  /// Time elapsed since [startDate]. For a resolved streak this is its
  /// actual lived duration (up to [completedAt]/[brokenAt]/[endDate]) — see
  /// [actualDuration] — not "time since start until now".
  Duration get elapsed {
    if (isActive) return DateTime.now().difference(startDate);
    return actualDuration;
  }

  /// Time left until [endDate] for an active timed streak; `null` for an
  /// open-ended streak or once the streak is no longer active.
  Duration? get remaining {
    final end = endDate;
    if (end == null || !isActive) return null;
    final diff = end.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  /// `elapsed / duration` for a timed streak, clamped to `[0, 1]`. Callers
  /// must not render this for an open-ended streak — there is no endpoint to
  /// be a percentage of (spec: show elapsed time instead).
  double get progress {
    final total = duration;
    if (total == null || total.inMicroseconds == 0) return 0;
    final ratio = elapsed.inMicroseconds / total.inMicroseconds;
    return ratio.clamp(0.0, 1.0);
  }

  /// The streak's actual lived duration, independent of timer ticks:
  /// - active, open-ended: `now - startDate` (still growing)
  /// - active, timed: `now - startDate` (still growing, capped implicitly by [remaining] elsewhere)
  /// - completed: `completedAt - startDate` (a naturally-completed timed
  ///   streak has `completedAt == endDate`)
  /// - broken: `brokenAt - startDate`
  Duration get actualDuration {
    if (isCompleted && completedAt != null) return completedAt!.difference(startDate);
    if (isBroken && brokenAt != null) return brokenAt!.difference(startDate);
    return DateTime.now().difference(startDate);
  }

  StreakEntity copyWith({
    String? id,
    DateTime? startDate,
    DateTime? endDate,
    bool clearEndDate = false,
    Duration? duration,
    bool clearDuration = false,
    StreakStatus? status,
    DateTime? completedAt,
    DateTime? brokenAt,
  }) {
    return StreakEntity(
      id: id ?? this.id,
      startDate: startDate ?? this.startDate,
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
      duration: clearDuration ? null : (duration ?? this.duration),
      status: status ?? this.status,
      completedAt: completedAt ?? this.completedAt,
      brokenAt: brokenAt ?? this.brokenAt,
    );
  }

  @override
  bool operator ==(Object other) => other is StreakEntity && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
