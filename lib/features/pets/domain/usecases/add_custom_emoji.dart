import 'package:uuid/uuid.dart';

import '../../../../core/errors/failures.dart';
import '../entities/pet_entity.dart';
import '../repositories/pet_repository.dart';

/// "Add Custom Emoji" flow (Section 4): validate the typed/pasted glyph,
/// persist it as a custom pet. Unlike [ImportCustomPet], there's no file to
/// copy — the emoji string itself *is* the asset, so it's stored verbatim
/// (Section 6: never assume an emoji is a single Dart character — sequences,
/// modifiers, and ZWJ joins are all just longer strings here).
class AddCustomEmoji {
  const AddCustomEmoji(this._repository);

  final PetRepository _repository;

  Future<PetEntity> call({required String emoji, required String name}) async {
    final trimmedEmoji = emoji.trim();
    if (trimmedEmoji.isEmpty) {
      throw const EmojiValidationFailure('Enter an emoji before saving.');
    }

    final pet = PetEntity(
      id: const Uuid().v4(),
      name: name.trim().isEmpty ? 'My Emoji' : name.trim(),
      type: PetType.emoji,
      emoji: trimmedEmoji,
      builtIn: false,
      createdAt: DateTime.now(),
    );

    await _repository.addCustomPet(pet);
    return pet;
  }
}
