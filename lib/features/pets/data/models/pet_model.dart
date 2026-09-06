import 'package:hive/hive.dart';

import '../../domain/entities/pet_entity.dart';

/// `typeId` picked from the same unused range as `streakModelTypeId` — see
/// that constant's doc for why the exact value doesn't matter beyond being
/// unique across registered adapters.
const int petModelTypeId = 12;

/// Persisted form of [PetEntity], stored in the `pets` Hive box for custom
/// pets only (built-in pets never round-trip through storage — they're
/// constructed in code, see `PetLocalDataSource.builtInPets`).
class PetModel extends PetEntity {
  const PetModel({
    required super.id,
    required super.name,
    required super.type,
    super.emoji,
    super.assetPath,
    required super.builtIn,
    super.createdAt,
    super.width,
    super.height,
  });

  factory PetModel.fromEntity(PetEntity entity) {
    return PetModel(
      id: entity.id,
      name: entity.name,
      type: entity.type,
      emoji: entity.emoji,
      assetPath: entity.assetPath,
      builtIn: entity.builtIn,
      createdAt: entity.createdAt,
      width: entity.width,
      height: entity.height,
    );
  }
}

/// Hand-written adapter (the project has no `build_runner`/codegen step
/// today) — field-indexed exactly like a generated adapter would be, so
/// adding a field later stays backward compatible with already-persisted
/// records. `type` is stored as its enum index, same approach as
/// `StreakModel.statusIndex`.
class PetModelAdapter extends TypeAdapter<PetModel> {
  @override
  final int typeId = petModelTypeId;

  @override
  PetModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read()};
    final createdAtMillis = fields[6] as int?;
    return PetModel(
      id: fields[0] as String,
      name: fields[1] as String,
      type: PetType.values[(fields[2] as int).clamp(0, PetType.values.length - 1)],
      emoji: fields[3] as String?,
      assetPath: fields[4] as String?,
      builtIn: fields[5] as bool? ?? false,
      createdAt: createdAtMillis == null ? null : DateTime.fromMillisecondsSinceEpoch(createdAtMillis),
      width: fields[7] as int?,
      height: fields[8] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, PetModel obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.type.index)
      ..writeByte(3)
      ..write(obj.emoji)
      ..writeByte(4)
      ..write(obj.assetPath)
      ..writeByte(5)
      ..write(obj.builtIn)
      ..writeByte(6)
      ..write(obj.createdAt?.millisecondsSinceEpoch)
      ..writeByte(7)
      ..write(obj.width)
      ..writeByte(8)
      ..write(obj.height);
  }

  @override
  int get hashCode => petModelTypeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is PetModelAdapter && runtimeType == other.runtimeType && typeId == other.typeId);
}
