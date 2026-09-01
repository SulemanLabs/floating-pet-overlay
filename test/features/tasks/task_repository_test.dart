import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:floating_pet_overlay/core/storage/local_storage.dart';
import 'package:floating_pet_overlay/features/tasks/data/datasources/task_local_datasource.dart';
import 'package:floating_pet_overlay/features/tasks/data/repositories/task_repository_impl.dart';
import 'package:floating_pet_overlay/features/tasks/domain/entities/task_entity.dart';
import 'package:floating_pet_overlay/features/tasks/presentation/providers/task_providers.dart';

void main() {
  late LocalStorage storage;
  late TaskRepositoryImpl repository;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storage = await LocalStorage.create();
    repository = TaskRepositoryImpl(TaskLocalDataSource(storage));
  });

  TaskEntity buildTask({required String id, required DateTime deadline, bool isCompleted = false}) {
    return TaskEntity(id: id, title: 'Task $id', deadline: deadline, isCompleted: isCompleted, createdAt: DateTime(2026));
  }

  test('getTasks returns an empty list when nothing has been added', () async {
    expect(await repository.getTasks(), isEmpty);
  });

  test('addTask persists and survives a fresh repository instance', () async {
    await repository.addTask(buildTask(id: 't1', deadline: DateTime(2026, 6, 1)));

    final reloaded = await TaskRepositoryImpl(TaskLocalDataSource(storage)).getTasks();

    expect(reloaded, hasLength(1));
    expect(reloaded.single.id, 't1');
  });

  test('updateTask replaces the matching task in place', () async {
    await repository.addTask(buildTask(id: 't1', deadline: DateTime(2026, 6, 1)));
    final tasks = await repository.getTasks();

    await repository.updateTask(tasks.single.copyWith(isCompleted: true));

    final updated = await repository.getTasks();
    expect(updated.single.isCompleted, isTrue);
  });

  test('deleteTask removes only the matching task', () async {
    await repository.addTask(buildTask(id: 't1', deadline: DateTime(2026, 6, 1)));
    await repository.addTask(buildTask(id: 't2', deadline: DateTime(2026, 6, 2)));

    await repository.deleteTask('t1');

    final remaining = await repository.getTasks();
    expect(remaining.map((t) => t.id), ['t2']);
  });

  group('nextDeadlineTask', () {
    test('returns null when there are no tasks', () {
      expect(nextDeadlineTask(const []), isNull);
    });

    test('returns null when every task is completed', () {
      final tasks = [buildTask(id: 't1', deadline: DateTime(2026, 6, 1), isCompleted: true)];
      expect(nextDeadlineTask(tasks), isNull);
    });

    test('returns the incomplete task with the soonest deadline', () {
      final tasks = [
        buildTask(id: 'late', deadline: DateTime(2026, 12, 1)),
        buildTask(id: 'soon', deadline: DateTime(2026, 6, 1)),
        buildTask(id: 'done-soonest', deadline: DateTime(2026, 1, 1), isCompleted: true),
      ];

      expect(nextDeadlineTask(tasks)?.id, 'soon');
    });
  });
}
