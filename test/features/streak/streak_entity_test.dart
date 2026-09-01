import 'package:flutter_test/flutter_test.dart';

import 'package:floating_pet_overlay/features/streak/domain/entities/streak_entity.dart';

void main() {
  group('open-ended (count-up) streak', () {
    test('isOpenEnded is true and remaining is null', () {
      final streak = StreakEntity(
        id: 's1',
        startDate: DateTime.now().subtract(const Duration(hours: 2)),
        status: StreakStatus.active,
      );

      expect(streak.isOpenEnded, isTrue);
      expect(streak.isTimed, isFalse);
      expect(streak.remaining, isNull);
    });

    test('elapsed is computed from now - startDate while active', () {
      final start = DateTime.now().subtract(const Duration(hours: 3, minutes: 30));
      final streak = StreakEntity(id: 's1', startDate: start, status: StreakStatus.active);

      expect(streak.elapsed.inMinutes, closeTo(210, 1));
    });

    test('never reports completed/broken on its own — no automatic expiration', () {
      final streak = StreakEntity(
        id: 's1',
        startDate: DateTime.now().subtract(const Duration(days: 30)),
        status: StreakStatus.active,
      );

      expect(streak.isActive, isTrue);
      expect(streak.status, StreakStatus.active);
    });
  });

  group('timed (countdown) streak', () {
    test('isTimed is true and progress reflects elapsed/duration', () {
      final start = DateTime.now().subtract(const Duration(hours: 6));
      final duration = const Duration(hours: 12);
      final streak = StreakEntity(
        id: 's1',
        startDate: start,
        endDate: start.add(duration),
        duration: duration,
        status: StreakStatus.active,
      );

      expect(streak.isTimed, isTrue);
      expect(streak.progress, closeTo(0.5, 0.01));
    });

    test('remaining counts down to endDate', () {
      final start = DateTime.now().subtract(const Duration(hours: 9));
      final duration = const Duration(hours: 12);
      final streak = StreakEntity(
        id: 's1',
        startDate: start,
        endDate: start.add(duration),
        duration: duration,
        status: StreakStatus.active,
      );

      expect(streak.remaining!.inHours, closeTo(3, 1));
    });

    test('remaining never goes negative once past endDate', () {
      final start = DateTime.now().subtract(const Duration(hours: 5));
      final streak = StreakEntity(
        id: 's1',
        startDate: start,
        endDate: start.add(const Duration(hours: 1)),
        duration: const Duration(hours: 1),
        status: StreakStatus.active,
      );

      expect(streak.remaining, Duration.zero);
    });
  });

  group('actual duration for resolved streaks', () {
    test('completed streak uses completedAt - startDate, not now', () {
      final start = DateTime(2026, 1, 1, 10, 0);
      final completedAt = DateTime(2026, 1, 1, 18, 30);
      final streak = StreakEntity(
        id: 's1',
        startDate: start,
        status: StreakStatus.completed,
        completedAt: completedAt,
      );

      expect(streak.actualDuration, const Duration(hours: 8, minutes: 30));
      expect(streak.elapsed, streak.actualDuration);
    });

    test('broken streak uses brokenAt - startDate, not now', () {
      final start = DateTime(2026, 1, 1, 8, 0);
      final brokenAt = DateTime(2026, 1, 1, 15, 32);
      final streak = StreakEntity(id: 's1', startDate: start, status: StreakStatus.broken, brokenAt: brokenAt);

      expect(streak.actualDuration, const Duration(hours: 7, minutes: 32));
    });

    test('a naturally-completed timed streak has completedAt == endDate', () {
      final start = DateTime(2026, 1, 1, 10, 0);
      final end = DateTime(2026, 1, 1, 22, 0);
      final streak = StreakEntity(
        id: 's1',
        startDate: start,
        endDate: end,
        duration: end.difference(start),
        status: StreakStatus.completed,
        completedAt: end,
      );

      expect(streak.actualDuration, const Duration(hours: 12));
    });
  });

  test('status flags are mutually exclusive', () {
    final active = StreakEntity(id: 's1', startDate: DateTime.now(), status: StreakStatus.active);
    final completed = StreakEntity(
      id: 's2',
      startDate: DateTime.now(),
      status: StreakStatus.completed,
      completedAt: DateTime.now(),
    );
    final broken = StreakEntity(id: 's3', startDate: DateTime.now(), status: StreakStatus.broken, brokenAt: DateTime.now());

    expect((active.isActive, active.isCompleted, active.isBroken), (true, false, false));
    expect((completed.isActive, completed.isCompleted, completed.isBroken), (false, true, false));
    expect((broken.isActive, broken.isCompleted, broken.isBroken), (false, false, true));
  });
}
