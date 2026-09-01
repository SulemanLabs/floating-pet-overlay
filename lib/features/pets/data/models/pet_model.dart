import 'dart:convert';

import '../../domain/entities/pet_entity.dart';

/// JSON-serializable form of [PetEntity], used for the custom-pet list
/// persisted in [LocalStorage] (built-in pets never round-trip through
/// JSON — they're constructed in code, see `PetLocalDataSource.builtInPets`).
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

  factory PetModel.fromJson(Map<String, dynamic> json) {
    return PetModel(
      id: json['id'] as String,
      name: json['name'] as String,
      type: PetType.values.byName(json['type'] as String),
      emoji: json['emoji'] as String?,
      assetPath: json['assetPath'] as String?,
      builtIn: json['builtIn'] as bool? ?? false,
      createdAt: json['createdAt'] == null ? null : DateTime.tryParse(json['createdAt'] as String),
      width: json['width'] as int?,
      height: json['height'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'emoji': emoji,
      'assetPath': assetPath,
      'builtIn': builtIn,
      'createdAt': createdAt?.toIso8601String(),
      'width': width,
      'height': height,
    };
  }

  static String encodeList(List<PetModel> pets) => jsonEncode(pets.map((p) => p.toJson()).toList());

  static List<PetModel> decodeList(String raw) {
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded.map((e) => PetModel.fromJson(e as Map<String, dynamic>)).toList();
  }
}
