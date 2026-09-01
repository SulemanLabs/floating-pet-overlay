import '../entities/task_entity.dart';
import '../repositories/task_repository.dart';

class GetTasks {
  const GetTasks(this._repository);

  final TaskRepository _repository;

  Future<List<TaskEntity>> call() => _repository.getTasks();
}
