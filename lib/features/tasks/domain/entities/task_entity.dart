/// A single reminder with a deadline. The pet reacts to whichever
/// incomplete task's deadline is soonest — see `TaskController` for how
/// that gets computed and pushed to the native overlay.
class TaskEntity {
  const TaskEntity({
    required this.id,
    required this.title,
    required this.deadline,
    this.isCompleted = false,
    required this.createdAt,
  });

  final String id;
  final String title;
  final DateTime deadline;
  final bool isCompleted;
  final DateTime createdAt;

  bool get isOverdue => !isCompleted && deadline.isBefore(DateTime.now());

  TaskEntity copyWith({String? id, String? title, DateTime? deadline, bool? isCompleted, DateTime? createdAt}) {
    return TaskEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      deadline: deadline ?? this.deadline,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) => other is TaskEntity && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
