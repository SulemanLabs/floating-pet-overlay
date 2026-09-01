/// Formats a deadline relative to now, e.g. "in 2h 15m" or "Overdue by 10m".
/// Mirrors the countdown format `DeadlineTicker.kt` shows on the floating
/// overlay, so the in-app task list and the on-screen pet read consistently.
String formatRelativeDeadline(DateTime deadline, {DateTime? now}) {
  final reference = now ?? DateTime.now();
  final diff = deadline.difference(reference);

  if (diff.isNegative) {
    return 'Overdue by ${_formatDuration(-diff)}';
  }
  return 'in ${_formatDuration(diff)}';
}

String _formatDuration(Duration duration) {
  final days = duration.inDays;
  final hours = duration.inHours % 24;
  final minutes = duration.inMinutes % 60;

  if (days > 0) return '${days}d ${hours}h';
  if (hours > 0) return '${hours}h ${minutes}m';
  if (minutes > 0) return '${minutes}m';
  return 'under a minute';
}
