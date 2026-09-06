import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:floating_streak/features/streak/data/datasources/streak_local_datasource.dart';
import 'package:floating_streak/features/streak/data/models/streak_model.dart';
import 'package:floating_streak/features/streak/data/repositories/streak_repository_impl.dart';
import 'package:floating_streak/features/streak/domain/entities/streak_entity.dart';

/// checkExpiration must run on startup/resume rather than depending on a
/// background timer, and a naturally-completed timed streak must stamp
/// `completedAt == endDate`, not `DateTime.now()` (spec §17).
void main() {
  late Directory tempDir;
  late Box<StreakModel> box;
  late StreakRepositoryImpl repository;

  setUpAll(() {
    if (!Hive.isAdapterRegistered(streakModelTypeId)) {
      Hive.registerAdapter(StreakModelAdapter());
    }
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('streak_expiration_test');
    Hive.init(tempDir.path);
    box = await Hive.openBox<StreakModel>('streaks_expiration_test');
    repository = StreakRepositoryImpl(StreakLocalDataSource(box));
  });

  tearDown(() async {
    if (box.isOpen) await box.close();
    await Hive.deleteBoxFromDisk('streaks_expiration_test', path: tempDir.path);
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  test('an open-ended streak is never touched by checkExpiration', () async {
    await repository.startStreak(
      StreakEntity(id: 's1', startDate: DateTime.now().subtract(const Duration(days: 10)), status: StreakStatus.active),
    );

    final result = await repository.checkExpiration();

    expect(result, isNull);
    expect((await repository.getCurrentStreak())?.isActive, isTrue);
  });

  test('a timed streak still before its endDate stays active', () async {
    final start = DateTime.now().subtract(const Duration(hours: 1));
    await repository.startStreak(
      StreakEntity(
        id: 's1',
        startDate: start,
        endDate: start.add(const Duration(hours: 12)),
        duration: const Duration(hours: 12),
        status: StreakStatus.active,
      ),
    );

    final result = await repository.checkExpiration();

    expect(result, isNull);
    expect((await repository.getCurrentStreak())?.isActive, isTrue);
  });

  test('a timed streak past its endDate is completed with completedAt == endDate', () async {
    final start = DateTime.now().subtract(const Duration(hours: 5));
    final end = start.add(const Duration(hours: 2));
    await repository.startStreak(
      StreakEntity(id: 's1', startDate: start, endDate: end, duration: const Duration(hours: 2), status: StreakStatus.active),
    );

    final result = await repository.checkExpiration();

    expect(result, isNotNull);
    expect(result!.status, StreakStatus.completed);
    // Hive persists timestamps as millisecond epochs (matching every other
    // stored timestamp in the app), so compare at that precision rather than
    // DateTime.now()'s microsecond precision.
    expect(result.completedAt!.millisecondsSinceEpoch, end.millisecondsSinceEpoch);
    expect(await repository.getCurrentStreak(), isNull);
  });

  test('a streak exactly at its endDate is treated as expired', () async {
    final start = DateTime.now().subtract(const Duration(hours: 1));
    final end = DateTime.now();
    await repository.startStreak(
      StreakEntity(id: 's1', startDate: start, endDate: end, duration: const Duration(hours: 1), status: StreakStatus.active),
    );

    final result = await repository.checkExpiration();

    expect(result?.status, StreakStatus.completed);
  });

  test('calling checkExpiration again after resolution is a no-op', () async {
    final start = DateTime.now().subtract(const Duration(hours: 3));
    final end = start.add(const Duration(hours: 1));
    await repository.startStreak(
      StreakEntity(id: 's1', startDate: start, endDate: end, duration: const Duration(hours: 1), status: StreakStatus.active),
    );

    await repository.checkExpiration();
    final second = await repository.checkExpiration();

    expect(second, isNull);
  });
}
