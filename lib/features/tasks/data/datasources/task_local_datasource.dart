import '../../../../core/storage/local_storage.dart';
import '../models/task_model.dart';

class TaskLocalDataSource {
  TaskLocalDataSource(this._storage);

  final LocalStorage _storage;

  static const _tasksKey = 'tasks.list';

  List<TaskModel> getTasks() {
    final raw = _storage.getString(_tasksKey);
    if (raw == null || raw.isEmpty) return const [];
    try {
      return TaskModel.decodeList(raw);
    } catch (_) {
      // Corrupted persisted data — fail safe rather than crash the tasks screen.
      return const [];
    }
  }

  Future<void> saveTasks(List<TaskModel> tasks) => _storage.setString(_tasksKey, TaskModel.encodeList(tasks));
}
