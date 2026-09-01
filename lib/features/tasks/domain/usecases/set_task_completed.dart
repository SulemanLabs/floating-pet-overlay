import '../entities/task_entity.dart';
import '../repositories/task_repository.dart';

class SetTaskCompleted {
  const SetTaskCompleted(this._repository);

  final TaskRepository _repository;

  Future<TaskEntity> call(TaskEntity task, bool isCompleted) async {
    final updated = task.copyWith(isCompleted: isCompleted);
    await _repository.updateTask(updated);
    return updated;
  }
}
