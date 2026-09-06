import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../../overlay/presentation/providers/overlay_providers.dart';
import '../../data/datasources/task_local_datasource.dart';
import '../../data/repositories/task_repository_impl.dart';
import '../../domain/entities/task_entity.dart';
import '../../domain/repositories/task_repository.dart';
import '../../domain/usecases/add_task.dart';
import '../../domain/usecases/delete_task.dart';
import '../../domain/usecases/get_tasks.dart';
import '../../domain/usecases/set_task_completed.dart';

final taskLocalDataSourceProvider = Provider<TaskLocalDataSource>((ref) {
  return TaskLocalDataSource(ref.watch(taskHiveBoxProvider));
});

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return TaskRepositoryImpl(ref.watch(taskLocalDataSourceProvider));
});

final getTasksProvider = Provider<GetTasks>((ref) => GetTasks(ref.watch(taskRepositoryProvider)));

final addTaskProvider = Provider<AddTask>((ref) => AddTask(ref.watch(taskRepositoryProvider)));

final setTaskCompletedProvider = Provider<SetTaskCompleted>((ref) => SetTaskCompleted(ref.watch(taskRepositoryProvider)));

final deleteTaskProvider = Provider<DeleteTask>((ref) => DeleteTask(ref.watch(taskRepositoryProvider)));

final taskControllerProvider = AsyncNotifierProvider<TaskController, List<TaskEntity>>(TaskController.new);

/// Finds the incomplete task whose deadline is soonest, or `null` if there
/// isn't one. Shared by the controller (to know what to push to the overlay)
/// and the tasks screen (to highlight it).
TaskEntity? nextDeadlineTask(List<TaskEntity> tasks) {
  final incomplete = tasks.where((t) => !t.isCompleted).toList()..sort((a, b) => a.deadline.compareTo(b.deadline));
  return incomplete.isEmpty ? null : incomplete.first;
}

class TaskController extends AsyncNotifier<List<TaskEntity>> {
  @override
  Future<List<TaskEntity>> build() async {
    final tasks = await ref.read(getTasksProvider).call();
    // Re-push on every cold start (app reinstall/update, or the native side
    // never having heard about it yet) so the overlay's countdown can't
    // silently drift out of sync with what Dart actually has persisted.
    await _syncNextDeadline(tasks);
    return tasks;
  }

  Future<void> addTask({required String title, required DateTime deadline}) async {
    await ref.read(addTaskProvider).call(title: title, deadline: deadline);
    await _reload();
  }

  Future<void> setCompleted(TaskEntity task, bool isCompleted) async {
    await ref.read(setTaskCompletedProvider).call(task, isCompleted);
    await _reload();
  }

  Future<void> deleteTask(String taskId) async {
    await ref.read(deleteTaskProvider).call(taskId);
    await _reload();
  }

  Future<void> _reload() async {
    final tasks = await ref.read(getTasksProvider).call();
    state = AsyncData(tasks);
    await _syncNextDeadline(tasks);
  }

  Future<void> _syncNextDeadline(List<TaskEntity> tasks) async {
    final next = nextDeadlineTask(tasks);
    await ref.read(overlayRepositoryProvider).syncNextDeadline(next?.deadline);
  }
}
