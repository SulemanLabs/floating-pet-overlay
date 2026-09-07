import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:floating_streak/app.dart';
import 'package:floating_streak/core/constants/platform_channel_constants.dart';
import 'package:floating_streak/core/providers/core_providers.dart';
import 'package:floating_streak/core/storage/local_storage.dart';
import 'package:floating_streak/features/pets/data/models/pet_model.dart';
import 'package:floating_streak/features/streak/data/models/streak_model.dart';
import 'package:floating_streak/features/tasks/data/models/task_model.dart';

void main() {
  const channel = MethodChannel(PlatformChannelConstants.controlChannel);

  late Directory tempDir;

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
      switch (call.method) {
        case PlatformChannelConstants.methodIsOverlayPermissionGranted:
        case PlatformChannelConstants.methodStartOverlay:
        case PlatformChannelConstants.methodStopOverlay:
        case PlatformChannelConstants.methodSyncSettings:
          return true;
        case PlatformChannelConstants.methodGetOverlayStatus:
          return 'stopped';
        default:
          return true;
      }
    });
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  testWidgets('Home screen renders with a default pet and start button', (WidgetTester tester) async {
    // Hive's real file I/O doesn't resolve on the fake async clock that
    // `testWidgets` runs its body under — it needs `runAsync` to actually
    // drive the real event loop (see the Flutter docs on `runAsync`).
    late LocalStorage storage;
    late Box<StreakModel> streakBox;
    late Box<TaskModel> taskBox;
    late Box<PetModel> petBox;
    await tester.runAsync(() async {
      tempDir = await Directory.systemTemp.createTemp('widget_hive_test');
      Hive.init(tempDir.path);
      if (!Hive.isAdapterRegistered(streakModelTypeId)) {
        Hive.registerAdapter(StreakModelAdapter());
      }
      if (!Hive.isAdapterRegistered(taskModelTypeId)) {
        Hive.registerAdapter(TaskModelAdapter());
      }
      if (!Hive.isAdapterRegistered(petModelTypeId)) {
        Hive.registerAdapter(PetModelAdapter());
      }
      storage = LocalStorage(await Hive.openBox('prefs_test'));
      streakBox = await Hive.openBox<StreakModel>('streaks_test');
      taskBox = await Hive.openBox<TaskModel>('tasks_test');
      petBox = await Hive.openBox<PetModel>('pets_test');
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localStorageProvider.overrideWithValue(storage),
          streakHiveBoxProvider.overrideWithValue(streakBox),
          taskHiveBoxProvider.overrideWithValue(taskBox),
          petHiveBoxProvider.overrideWithValue(petBox),
        ],
        child: const FloatingPetOverlayApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Floating Streak'), findsOneWidget);
    expect(find.text('Start floating pet'), findsOneWidget);
  });
}
