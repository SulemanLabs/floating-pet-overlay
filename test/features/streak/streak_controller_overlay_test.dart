import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:floating_pet_overlay/core/errors/failures.dart';
import 'package:floating_pet_overlay/core/platform/overlay_platform_events.dart';
import 'package:floating_pet_overlay/features/overlay/domain/repositories/overlay_repository.dart';
import 'package:floating_pet_overlay/features/overlay/presentation/providers/overlay_providers.dart';
import 'package:floating_pet_overlay/features/pets/domain/entities/pet_entity.dart';
import 'package:floating_pet_overlay/features/settings/domain/entities/overlay_settings.dart';
import 'package:floating_pet_overlay/features/streak/domain/entities/streak_entity.dart';
import 'package:floating_pet_overlay/features/streak/domain/entities/streak_stats.dart';
import 'package:floating_pet_overlay/features/streak/domain/repositories/streak_repository.dart';
import 'package:floating_pet_overlay/features/streak/presentation/providers/streak_providers.dart';

/// In-memory fake — this project has no mocking library, so hand-written
/// fakes are the existing convention.
class FakeStreakRepository implements StreakRepository {
  final Map<String, StreakEntity> store = {};

  @override
  Future<StreakEntity?> getCurrentStreak() async {
    for (final streak in store.values) {
      if (streak.isActive) return streak;
    }
    return null;
  }

  @override
  Future<List<StreakEntity>> getStreakHistory() async {
    final list = store.values.toList()..sort((a, b) => b.startDate.compareTo(a.startDate));
    return list;
  }

  @override
  Future<void> startStreak(StreakEntity streak) async {
    if (await getCurrentStreak() != null) {
      throw const StreakValidationFailure('A streak is already active.');
    }
    store[streak.id] = streak;
  }

  @override
  Future<StreakEntity> completeStreak(String streakId) async {
    final current = store[streakId];
    if (current == null) throw const StreakValidationFailure('Not found');
    final updated = current.copyWith(status: StreakStatus.completed, completedAt: DateTime.now());
    store[streakId] = updated;
    return updated;
  }

  @override
  Future<StreakEntity> breakStreak(String streakId) async {
    final current = store[streakId];
    if (current == null) throw const StreakValidationFailure('Not found');
    final updated = current.copyWith(status: StreakStatus.broken, brokenAt: DateTime.now());
    store[streakId] = updated;
    return updated;
  }

  @override
  Future<StreakEntity?> checkExpiration() async {
    final current = await getCurrentStreak();
    if (current == null || current.isOpenEnded) return null;
    if (!DateTime.now().isBefore(current.endDate!)) {
      final updated = current.copyWith(status: StreakStatus.completed, completedAt: current.endDate);
      store[current.id] = updated;
      return updated;
    }
    return null;
  }

  @override
  Future<void> deleteStreak(String streakId) async => store.remove(streakId);

  @override
  Future<StreakStats> getStats() async => StreakStats.empty;
}

class RecordedStreakSync {
  const RecordedStreakSync({required this.mode, required this.status, required this.startDate, this.endDate});

  final String mode;
  final String status;
  final DateTime startDate;
  final DateTime? endDate;
}

/// Records every `syncStreak`/`clearStreak` call so tests can assert on the
/// controller's overlay-sync behavior without a real `MethodChannel`.
class FakeOverlayRepository implements OverlayRepository {
  final List<RecordedStreakSync> syncCalls = [];
  int clearCallCount = 0;
  bool throwOnCalls = false;

  @override
  Future<void> syncStreak({required String mode, required String status, required DateTime startDate, DateTime? endDate}) async {
    if (throwOnCalls) throw const PlatformBridgeFailure('overlay unavailable');
    syncCalls.add(RecordedStreakSync(mode: mode, status: status, startDate: startDate, endDate: endDate));
  }

  @override
  Future<void> clearStreak() async {
    if (throwOnCalls) throw const PlatformBridgeFailure('overlay unavailable');
    clearCallCount++;
  }

  @override
  Stream<OverlayPlatformEvent> get events => const Stream.empty();

  @override
  Future<bool> isOverlayPermissionGranted() async => true;

  @override
  Future<void> requestOverlayPermission() async {}

  @override
  Future<bool> isNotificationPermissionGranted() async => true;

  @override
  Future<bool> requestNotificationPermission() async => true;

  @override
  Future<void> startOverlay({required PetEntity pet, required OverlaySettings settings}) async {}

  @override
  Future<void> stopOverlay() async {}

  @override
  Future<void> updatePet(PetEntity pet) async {}

  @override
  Future<void> updateSize(double sizePercent) async {}

  @override
  Future<void> updateOpacity(double opacity) async {}

  @override
  Future<void> updateSpeed(double speed) async {}

  @override
  Future<void> setMovementEnabled(bool enabled) async {}

  @override
  Future<void> syncSettings({required PetEntity pet, required OverlaySettings settings}) async {}

  @override
  Future<void> syncNextDeadline(DateTime? deadline) async {}
}

void main() {
  late FakeStreakRepository fakeStreakRepository;
  late FakeOverlayRepository fakeOverlayRepository;
  late ProviderContainer container;

  setUp(() {
    fakeStreakRepository = FakeStreakRepository();
    fakeOverlayRepository = FakeOverlayRepository();
    container = ProviderContainer(
      overrides: [
        streakRepositoryProvider.overrideWithValue(fakeStreakRepository),
        overlayRepositoryProvider.overrideWithValue(fakeOverlayRepository),
      ],
    );
    addTearDown(container.dispose);
  });

  test('start() persists the streak and syncs it to the overlay as active', () async {
    await container.read(streakControllerProvider.future);
    final notifier = container.read(streakControllerProvider.notifier);

    await notifier.start(duration: null);

    expect(container.read(currentStreakProvider), isNotNull);
    expect(fakeOverlayRepository.syncCalls, isNotEmpty);
    expect(fakeOverlayRepository.syncCalls.last.mode, 'count_up');
    expect(fakeOverlayRepository.syncCalls.last.status, 'active');
  });

  test('start() with a duration syncs mode "countdown"', () async {
    await container.read(streakControllerProvider.future);
    final notifier = container.read(streakControllerProvider.notifier);

    await notifier.start(duration: const Duration(hours: 6));

    expect(fakeOverlayRepository.syncCalls.last.mode, 'countdown');
    expect(fakeOverlayRepository.syncCalls.last.endDate, isNotNull);
  });

  test('completeCurrent() pushes a terminal "completed" sync, then clears the badge', () async {
    await container.read(streakControllerProvider.future);
    final notifier = container.read(streakControllerProvider.notifier);
    await notifier.start(duration: null);
    fakeOverlayRepository.syncCalls.clear();

    await notifier.completeCurrent();

    expect(fakeOverlayRepository.syncCalls.any((c) => c.status == 'completed'), isTrue);
    expect(fakeOverlayRepository.clearCallCount, greaterThan(0));
    expect(container.read(currentStreakProvider), isNull);
  });

  test('breakCurrent() pushes a terminal "broken" sync, then clears the badge', () async {
    await container.read(streakControllerProvider.future);
    final notifier = container.read(streakControllerProvider.notifier);
    await notifier.start(duration: null);
    fakeOverlayRepository.syncCalls.clear();

    await notifier.breakCurrent();

    expect(fakeOverlayRepository.syncCalls.any((c) => c.status == 'broken'), isTrue);
    expect(fakeOverlayRepository.clearCallCount, greaterThan(0));
    expect(container.read(currentStreakProvider), isNull);
  });

  test('handleAppResumed() detects an expired timed streak and completes it', () async {
    await container.read(streakControllerProvider.future);
    final notifier = container.read(streakControllerProvider.notifier);
    await notifier.start(duration: const Duration(hours: 1));
    final activeId = container.read(currentStreakProvider)!.id;

    // Simulate the deadline having passed while the app was backgrounded —
    // no timer ticked this down, the timestamp is just rewritten.
    final stale = fakeStreakRepository.store[activeId]!;
    fakeStreakRepository.store[activeId] = stale.copyWith(
      startDate: stale.startDate.subtract(const Duration(hours: 2)),
      endDate: stale.endDate!.subtract(const Duration(hours: 2)),
    );

    await notifier.handleAppResumed();

    final history = container.read(streakHistoryProvider);
    expect(history.single.status, StreakStatus.completed);
    expect(history.single.completedAt, history.single.endDate);
    expect(container.read(currentStreakProvider), isNull);
  });

  test('a Failure thrown by the overlay repository never propagates out of the controller', () async {
    fakeOverlayRepository.throwOnCalls = true;
    await container.read(streakControllerProvider.future);
    final notifier = container.read(streakControllerProvider.notifier);

    await notifier.start(duration: null);
    expect(container.read(currentStreakProvider), isNotNull);

    await notifier.completeCurrent();
    expect(container.read(currentStreakProvider), isNull);
  });

  test('starting a second streak while one is active surfaces an error, not a crash', () async {
    await container.read(streakControllerProvider.future);
    final notifier = container.read(streakControllerProvider.notifier);
    await notifier.start(duration: null);

    await notifier.start(duration: null);

    final state = container.read(streakControllerProvider).value!;
    expect(state.errorMessage, isNotNull);
  });
}
