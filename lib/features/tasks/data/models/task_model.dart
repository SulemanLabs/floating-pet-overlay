import 'package:hive/hive.dart';

import '../../domain/entities/task_entity.dart';

/// `typeId` picked from the same unused range as [streakModelTypeId] — see
/// that constant's doc for why the exact value doesn't matter beyond being
/// unique across registered adapters.
const int taskModelTypeId = 11;

class TaskModel extends TaskEntity {
  const TaskModel({
    required super.id,
    required super.title,
    required super.deadline,
    super.isCompleted,
    required super.createdAt,
  });

  factory TaskModel.fromEntity(TaskEntity entity) {
    return TaskModel(
      id: entity.id,
      title: entity.title,
      deadline: entity.deadline,
      isCompleted: entity.isCompleted,
      createdAt: entity.createdAt,
    );
  }
}

/// Hand-written adapter (the project has no `build_runner`/codegen step
/// today) — field-indexed exactly like a generated adapter would be, so
/// adding a field later stays backward compatible with already-persisted
/// records.
class TaskModelAdapter extends TypeAdapter<TaskModel> {
  @override
  final int typeId = taskModelTypeId;

  @override
  TaskModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read()};
    return TaskModel(
      id: fields[0] as String,
      title: fields[1] as String,
      deadline: DateTime.fromMillisecondsSinceEpoch(fields[2] as int),
      isCompleted: fields[3] as bool? ?? false,
      createdAt: DateTime.fromMillisecondsSinceEpoch(fields[4] as int),
    );
  }

  @override
  void write(BinaryWriter writer, TaskModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.deadline.millisecondsSinceEpoch)
      ..writeByte(3)
      ..write(obj.isCompleted)
      ..writeByte(4)
      ..write(obj.createdAt.millisecondsSinceEpoch);
  }

  @override
  int get hashCode => taskModelTypeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is TaskModelAdapter && runtimeType == other.runtimeType && typeId == other.typeId);
}
