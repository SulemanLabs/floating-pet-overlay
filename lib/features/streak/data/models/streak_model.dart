import 'package:hive/hive.dart';

import '../../domain/entities/streak_entity.dart';

/// `typeId` picked from an unused range — this is the only Hive type
/// registered in the app today, so any value works, but keeping it here
/// (rather than 0) leaves room for other features to adopt Hive later
/// without a collision.
const int streakModelTypeId = 10;

/// Hive-persisted mirror of [StreakEntity]. Only source-of-truth timestamps
/// are stored — no `remainingSeconds`/`elapsedSeconds`/`progress`, those are
/// always computed from these fields at read time (see the entity's getters).
class StreakModel {
  const StreakModel({
    required this.id,
    required this.startDateMillis,
    this.endDateMillis,
    this.durationMillis,
    required this.statusIndex,
    this.completedAtMillis,
    this.brokenAtMillis,
  });

  final String id;
  final int startDateMillis;
  final int? endDateMillis;
  final int? durationMillis;
  final int statusIndex;
  final int? completedAtMillis;
  final int? brokenAtMillis;

  factory StreakModel.fromEntity(StreakEntity entity) {
    return StreakModel(
      id: entity.id,
      startDateMillis: entity.startDate.millisecondsSinceEpoch,
      endDateMillis: entity.endDate?.millisecondsSinceEpoch,
      durationMillis: entity.duration?.inMilliseconds,
      statusIndex: entity.status.index,
      completedAtMillis: entity.completedAt?.millisecondsSinceEpoch,
      brokenAtMillis: entity.brokenAt?.millisecondsSinceEpoch,
    );
  }

  StreakEntity toEntity() {
    return StreakEntity(
      id: id,
      startDate: DateTime.fromMillisecondsSinceEpoch(startDateMillis),
      endDate: endDateMillis == null ? null : DateTime.fromMillisecondsSinceEpoch(endDateMillis!),
      duration: durationMillis == null ? null : Duration(milliseconds: durationMillis!),
      status: StreakStatus.values[statusIndex.clamp(0, StreakStatus.values.length - 1)],
      completedAt: completedAtMillis == null ? null : DateTime.fromMillisecondsSinceEpoch(completedAtMillis!),
      brokenAt: brokenAtMillis == null ? null : DateTime.fromMillisecondsSinceEpoch(brokenAtMillis!),
    );
  }
}

/// Hand-written adapter (the project has no `build_runner`/codegen step
/// today) — field-indexed exactly like a generated adapter would be, so
/// adding a field later stays backward compatible with already-persisted
/// records.
class StreakModelAdapter extends TypeAdapter<StreakModel> {
  @override
  final int typeId = streakModelTypeId;

  @override
  StreakModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read()};
    return StreakModel(
      id: fields[0] as String,
      startDateMillis: fields[1] as int,
      endDateMillis: fields[2] as int?,
      durationMillis: fields[3] as int?,
      statusIndex: fields[4] as int,
      completedAtMillis: fields[5] as int?,
      brokenAtMillis: fields[6] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, StreakModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.startDateMillis)
      ..writeByte(2)
      ..write(obj.endDateMillis)
      ..writeByte(3)
      ..write(obj.durationMillis)
      ..writeByte(4)
      ..write(obj.statusIndex)
      ..writeByte(5)
      ..write(obj.completedAtMillis)
      ..writeByte(6)
      ..write(obj.brokenAtMillis);
  }

  @override
  int get hashCode => streakModelTypeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is StreakModelAdapter && runtimeType == other.runtimeType && typeId == other.typeId);
}
