/// Formats streak durations for display. Mirrors the spirit of
/// `deadline_formatter.dart`, but streaks need two distinct shapes: a compact
/// dashboard-style duration ("08h 30m") and a full HH:MM:SS clock ("03h 42m
/// 15s") for tighter, second-accurate contexts (current-streak card, native
/// overlay badge).
///
/// Always fed a [Duration] computed from stored timestamps by the caller —
/// never accumulate/decrement this value itself.
String formatStreakDuration(Duration duration, {bool includeSeconds = false}) {
  final clamped = duration.isNegative ? Duration.zero : duration;
  final days = clamped.inDays;
  final hours = clamped.inHours % 24;
  final minutes = clamped.inMinutes % 60;
  final seconds = clamped.inSeconds % 60;

  if (days > 0) {
    return includeSeconds
        ? '${days}d ${_pad(hours)}h ${_pad(minutes)}m ${_pad(seconds)}s'
        : '${days}d ${_pad(hours)}h ${_pad(minutes)}m';
  }
  return includeSeconds
      ? '${_pad(hours)}h ${_pad(minutes)}m ${_pad(seconds)}s'
      : '${_pad(hours)}h ${_pad(minutes)}m';
}

/// A compact `HH:MM:SS` clock, growing to `Dd HH:MM:SS` past a day. Used for
/// the current-streak card's live tick, matching the native overlay's format.
String formatStreakClock(Duration duration) {
  final clamped = duration.isNegative ? Duration.zero : duration;
  final days = clamped.inDays;
  final hours = clamped.inHours % 24;
  final minutes = clamped.inMinutes % 60;
  final seconds = clamped.inSeconds % 60;

  final clock = '${_pad(hours)}:${_pad(minutes)}:${_pad(seconds)}';
  return days > 0 ? '${days}d $clock' : clock;
}

String _pad(int value) => value.toString().padLeft(2, '0');
