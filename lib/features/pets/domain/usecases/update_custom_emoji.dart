import '../../../../core/errors/failures.dart';
import '../entities/pet_entity.dart';
import '../repositories/pet_repository.dart';

/// "Edit Custom Emoji" flow (Section 20): updates an existing custom emoji
/// pet's glyph and/or name in place, keeping its id — never creates a
/// duplicate record.
class UpdateCustomEmoji {
  const UpdateCustomEmoji(this._repository);

  final PetRepository _repository;

  Future<PetEntity> call({required PetEntity existing, required String emoji, required String name}) async {
    if (existing.builtIn) {
      throw const EmojiValidationFailure('Built-in pets can\'t be edited.');
    }
    final trimmedEmoji = emoji.trim();
    if (trimmedEmoji.isEmpty) {
      throw const EmojiValidationFailure('Enter an emoji before saving.');
    }

    final updated = existing.copyWith(emoji: trimmedEmoji, name: name.trim().isEmpty ? existing.name : name.trim());

    await _repository.updateCustomPet(updated);
    return updated;
  }
}
