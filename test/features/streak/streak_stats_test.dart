import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:floating_streak/features/streak/data/datasources/streak_local_datasource.dart';
import 'package:floating_streak/features/streak/data/models/streak_model.dart';
import 'package:floating_streak/features/streak/data/repositories/streak_repository_impl.dart';
import 'package:floating_streak/features/streak/domain/entities/streak_entity.dart';

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
    tempDir = await Directory.systemTemp.createTemp('streak_stats_test');
    Hive.init(tempDir.path);
    box = await Hive.openBox<StreakModel>('streaks_stats_test');
    repository = StreakRepositoryImpl(StreakLocalDataSource(box));
  });

  tearDown(() async {
    if (box.isOpen) await box.close();
    await Hive.deleteBoxFromDisk('streaks_stats_test', path: tempDir.path);
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  test('stats on an empty history are all zero', () async {
    final stats = await repository.getStats();

    expect(stats.totalStreaks, 0);
    expect(stats.completedStreaks, 0);
    expect(stats.brokenStreaks, 0);
    expect(stats.successRate, 0);
    expect(stats.currentStreak, isNull);
    expect(stats.longestStreak, Duration.zero);
  });

  test('success rate only counts resolved (completed/broken) streaks, not the active one', () async {
    // 2 completed, 1 broken -> 2/3 = 66.67%; the still-active streak must not
    // shift this denominator.
    await repository.startStreak(StreakEntity(id: 'c1', startDate: DateTime(2026, 1, 1), status: StreakStatus.active));
    await repository.completeStreak('c1');
    await repository.startStreak(StreakEntity(id: 'c2', startDate: DateTime(2026, 1, 2), status: StreakStatus.active));
    await repository.completeStreak('c2');
    await repository.startStreak(StreakEntity(id: 'b1', startDate: DateTime(2026, 1, 3), status: StreakStatus.active));
    await repository.breakStreak('b1');
    await repository.startStreak(StreakEntity(id: 'active', startDate: DateTime.now(), status: StreakStatus.active));

    final stats = await repository.getStats();

    expect(stats.totalStreaks, 4);
    expect(stats.completedStreaks, 2);
    expect(stats.brokenStreaks, 1);
    expect(stats.successRate, closeTo(200 / 3, 0.01));
    expect(stats.currentStreak, isNotNull);
  });

  test('longest streak is the largest actual duration, including a broken run', () async {
    // A broken streak that ran for a long time is still the longest the
    // user sustained — see StreakStats' doc comment for the rationale.
    final shortStart = DateTime(2026, 1, 1, 10, 0);
    await repository.startStreak(StreakEntity(id: 'short', startDate: shortStart, status: StreakStatus.active));
    await repository.completeStreak('short'); // ~instant duration

    final longStart = DateTime.now().subtract(const Duration(days: 5));
    await repository.startStreak(StreakEntity(id: 'long-broken', startDate: longStart, status: StreakStatus.active));
    await repository.breakStreak('long-broken');

    final stats = await repository.getStats();

    expect(stats.longestStreak.inDays, greaterThanOrEqualTo(4));
  });

  test('successRate is 0 (not NaN) when there are zero resolved streaks', () async {
    await repository.startStreak(StreakEntity(id: 'active', startDate: DateTime.now(), status: StreakStatus.active));

    final stats = await repository.getStats();

    expect(stats.successRate, 0);
  });
}
