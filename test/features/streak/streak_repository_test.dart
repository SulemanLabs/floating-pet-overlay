import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:floating_streak/core/errors/failures.dart';
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
    tempDir = await Directory.systemTemp.createTemp('streak_hive_test');
    Hive.init(tempDir.path);
    box = await Hive.openBox<StreakModel>('streaks_test');
    repository = StreakRepositoryImpl(StreakLocalDataSource(box));
  });

  tearDown(() async {
    if (box.isOpen) await box.close();
    await Hive.deleteBoxFromDisk('streaks_test', path: tempDir.path);
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  StreakEntity buildStreak({
    required String id,
    required DateTime startDate,
    DateTime? endDate,
    Duration? duration,
    StreakStatus status = StreakStatus.active,
  }) {
    return StreakEntity(id: id, startDate: startDate, endDate: endDate, duration: duration, status: status);
  }

  test('getCurrentStreak returns null when nothing has been started', () async {
    expect(await repository.getCurrentStreak(), isNull);
  });

  test('startStreak persists an open-ended active streak as the current one', () async {
    await repository.startStreak(buildStreak(id: 's1', startDate: DateTime(2026, 1, 1, 10)));

    final current = await repository.getCurrentStreak();
    expect(current?.id, 's1');
    expect(current?.isOpenEnded, isTrue);
    expect(current?.isActive, isTrue);
  });

  test('startStreak persists a timed streak with its endDate/duration intact', () async {
    final start = DateTime(2026, 1, 1, 10);
    final duration = const Duration(hours: 12);
    await repository.startStreak(buildStreak(id: 's1', startDate: start, endDate: start.add(duration), duration: duration));

    final current = await repository.getCurrentStreak();
    expect(current?.isTimed, isTrue);
    expect(current?.endDate, start.add(duration));
    expect(current?.duration, duration);
  });

  test('data survives closing the box and reopening a fresh repository instance', () async {
    await repository.startStreak(buildStreak(id: 's1', startDate: DateTime(2026, 1, 1, 10)));
    await box.close();

    box = await Hive.openBox<StreakModel>('streaks_test');
    final reloaded = StreakRepositoryImpl(StreakLocalDataSource(box));

    final current = await reloaded.getCurrentStreak();
    expect(current?.id, 's1');
  });

  test('completeStreak marks the streak completed with completedAt stamped now', () async {
    await repository.startStreak(buildStreak(id: 's1', startDate: DateTime.now().subtract(const Duration(hours: 1))));

    final resolved = await repository.completeStreak('s1');

    expect(resolved.status, StreakStatus.completed);
    expect(resolved.completedAt, isNotNull);
    expect(await repository.getCurrentStreak(), isNull);
  });

  test('breakStreak marks the streak broken with brokenAt stamped now', () async {
    await repository.startStreak(buildStreak(id: 's1', startDate: DateTime.now()));

    final resolved = await repository.breakStreak('s1');

    expect(resolved.status, StreakStatus.broken);
    expect(resolved.brokenAt, isNotNull);
    expect(await repository.getCurrentStreak(), isNull);
  });

  test('completeStreak throws for an unknown id', () async {
    await expectLater(repository.completeStreak('missing'), throwsA(isA<StreakValidationFailure>()));
  });

  test('breakStreak throws for an unknown id', () async {
    await expectLater(repository.breakStreak('missing'), throwsA(isA<StreakValidationFailure>()));
  });

  test('deleteStreak removes only the matching record', () async {
    await repository.startStreak(buildStreak(id: 's1', startDate: DateTime(2026, 1, 1)));
    await repository.completeStreak('s1');
    await repository.startStreak(buildStreak(id: 's2', startDate: DateTime(2026, 1, 2)));

    await repository.deleteStreak('s1');

    final remaining = await repository.getStreakHistory();
    expect(remaining.map((s) => s.id), ['s2']);
  });

  test('getStreakHistory is sorted newest-start-first', () async {
    await repository.startStreak(buildStreak(id: 'old', startDate: DateTime(2026, 1, 1)));
    await repository.completeStreak('old');
    await repository.startStreak(buildStreak(id: 'new', startDate: DateTime(2026, 6, 1)));

    final history = await repository.getStreakHistory();
    expect(history.map((s) => s.id), ['new', 'old']);
  });
}
