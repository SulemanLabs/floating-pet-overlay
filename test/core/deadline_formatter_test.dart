import 'package:flutter_test/flutter_test.dart';

import 'package:floating_pet_overlay/core/utils/deadline_formatter.dart';

void main() {
  final now = DateTime(2026, 1, 1, 12, 0, 0);

  test('formats a future deadline in days and hours', () {
    final deadline = now.add(const Duration(days: 2, hours: 3));
    expect(formatRelativeDeadline(deadline, now: now), 'in 2d 3h');
  });

  test('formats a future deadline in hours and minutes', () {
    final deadline = now.add(const Duration(hours: 1, minutes: 30));
    expect(formatRelativeDeadline(deadline, now: now), 'in 1h 30m');
  });

  test('formats a future deadline under an hour in minutes', () {
    final deadline = now.add(const Duration(minutes: 15));
    expect(formatRelativeDeadline(deadline, now: now), 'in 15m');
  });

  test('formats a deadline under a minute away', () {
    final deadline = now.add(const Duration(seconds: 30));
    expect(formatRelativeDeadline(deadline, now: now), 'in under a minute');
  });

  test('formats an overdue deadline', () {
    final deadline = now.subtract(const Duration(hours: 2, minutes: 10));
    expect(formatRelativeDeadline(deadline, now: now), 'Overdue by 2h 10m');
  });
}
