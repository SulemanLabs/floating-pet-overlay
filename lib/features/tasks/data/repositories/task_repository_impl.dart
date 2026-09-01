import '../../domain/entities/task_entity.dart';
import '../../domain/repositories/task_repository.dart';
import '../datasources/task_local_datasource.dart';
import '../models/task_model.dart';

class TaskRepositoryImpl implements TaskRepository {
  TaskRepositoryImpl(this._localDataSource);

  final TaskLocalDataSource _localDataSource;

  @override
  Future<List<TaskEntity>> getTasks() async => _localDataSource.getTasks();

  @override
  Future<void> addTask(TaskEntity task) async {
    final current = _localDataSource.getTasks();
    await _localDataSource.saveTasks([...current, TaskModel.fromEntity(task)]);
  }

  @override
  Future<void> updateTask(TaskEntity task) async {
    final current = _localDataSource.getTasks();
    final updated = [
      for (final existing in current)
        if (existing.id == task.id) TaskModel.fromEntity(task) else existing,
    ];
    await _localDataSource.saveTasks(updated);
  }

  @override
  Future<void> deleteTask(String taskId) async {
    final current = _localDataSource.getTasks();
    await _localDataSource.saveTasks(current.where((task) => task.id != taskId).toList());
  }
}
