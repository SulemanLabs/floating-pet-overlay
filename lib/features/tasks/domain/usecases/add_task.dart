import 'package:uuid/uuid.dart';

import '../entities/task_entity.dart';
import '../repositories/task_repository.dart';

class AddTask {
  const AddTask(this._repository);

  final TaskRepository _repository;

  Future<TaskEntity> call({required String title, required DateTime deadline}) async {
    final task = TaskEntity(
      id: const Uuid().v4(),
      title: title.trim().isEmpty ? 'Untitled task' : title.trim(),
      deadline: deadline,
      createdAt: DateTime.now(),
    );
    await _repository.addTask(task);
    return task;
  }
}
