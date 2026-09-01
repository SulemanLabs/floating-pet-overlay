/// How a pet's visual content should be rendered, both in Flutter previews
/// and by the native `PetRenderer` inside the overlay window.
enum PetType { emoji, image, gif, lottie }

class PetEntity {
  const PetEntity({
    required this.id,
    required this.name,
    required this.type,
    this.emoji,
    this.assetPath,
    required this.builtIn,
    this.createdAt,
    this.width,
    this.height,
  });

  final String id;
  final String name;
  final PetType type;
  final String? emoji;

  /// Absolute path to the imported file (image/gif/lottie). Null for emoji pets.
  final String? assetPath;
  final bool builtIn;
  final DateTime? createdAt;

  /// Intrinsic pixel dimensions of the source asset, captured at import time.
  /// Informational only — the overlay always renders the pet at the user's
  /// configured size, scaling this asset to fit. Null for emoji and Lottie
  /// pets (a Lottie composition has its own intrinsic size, not tracked here).
  final int? width;
  final int? height;

  PetEntity copyWith({
    String? id,
    String? name,
    PetType? type,
    String? emoji,
    String? assetPath,
    bool? builtIn,
    DateTime? createdAt,
    int? width,
    int? height,
  }) {
    return PetEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      emoji: emoji ?? this.emoji,
      assetPath: assetPath ?? this.assetPath,
      builtIn: builtIn ?? this.builtIn,
      createdAt: createdAt ?? this.createdAt,
      width: width ?? this.width,
      height: height ?? this.height,
    );
  }

  @override
  bool operator ==(Object other) => other is PetEntity && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
