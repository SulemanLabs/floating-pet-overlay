import 'package:flutter/material.dart';

import '../../../../core/utils/streak_duration_formatter.dart';
import '../controllers/streak_countdown_controller.dart';

/// Renders a live-ticking `08h 30m` / `00:47:21` value, prefixed with an
/// icon. Takes an already-computed [StreakCountdownValue] rather than
/// watching the provider itself, so it stays a plain, easily-reusable/
/// testable widget — the parent screen/card owns the
/// `ref.watch(streakCountdownProvider)` call.
class StreakCountdown extends StatelessWidget {
  const StreakCountdown({super.key, required this.value, this.style, this.includeSeconds = true});

  final StreakCountdownValue value;
  final TextStyle? style;
  final bool includeSeconds;

  /// Countdown mode with under an hour left gets a subtler "pay attention"
  /// glyph instead of the normal flame — matches the native overlay's
  /// warning state (spec §33), never an aggressive animation.
  bool get _isUrgent => !value.isCountUp && value.displayDuration.inMinutes < 60;

  @override
  Widget build(BuildContext context) {
    final text = includeSeconds ? formatStreakClock(value.displayDuration) : formatStreakDuration(value.displayDuration);
    final iconSize = (style?.fontSize ?? 14) * 0.85;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(_isUrgent ? Icons.timer_outlined : Icons.local_fire_department_outlined, size: iconSize, color: style?.color),
        SizedBox(width: iconSize * 0.3),
        Text(text, style: style),
      ],
    );
  }
}
