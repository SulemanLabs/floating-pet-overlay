import 'package:hive/hive.dart';

import '../models/task_model.dart';

/// Thin wrapper over the `tasks` Hive box — the only place in the tasks
/// feature that touches Hive directly, mirroring `StreakLocalDataSource`'s
/// role for the `streaks` box.
class TaskLocalDataSource {
  TaskLocalDataSource(this._box);

  final Box<TaskModel> _box;

  List<TaskModel> getTasks() {
    final tasks = <TaskModel>[];
    for (final key in _box.keys) {
      try {
        final model = _box.get(key);
        if (model != null) tasks.add(model);
      } catch (_) {
        // A single corrupted record must not take down the whole tasks list.
        continue;
      }
    }
    return tasks;
  }

  Future<void> saveTasks(List<TaskModel> tasks) async {
    await _box.clear();
    await _box.putAll({for (final task in tasks) task.id: task});
  }
}
