import '../repositories/task_repository.dart';

class DeleteTask {
  const DeleteTask(this._repository);

  final TaskRepository _repository;

  Future<void> call(String taskId) => _repository.deleteTask(taskId);
}
