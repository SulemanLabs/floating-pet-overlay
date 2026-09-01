import '../entities/pet_entity.dart';

abstract class PetRepository {
  /// Built-in pets plus any user-imported pets, newest custom pets last.
  Future<List<PetEntity>> getPets();

  Future<PetEntity> getSelectedPet();

  Future<void> selectPet(String petId);

  /// Appends an already-imported (validated, copied into app storage) pet
  /// to the custom pet list. See `ImportCustomPet` for the full import flow.
  Future<void> addCustomPet(PetEntity pet);

  /// Removes a custom pet's metadata. Never deletes the underlying asset
  /// file — see `DeleteCustomPet` for the full delete flow, which does both.
  /// Falls back the selected pet to the default built-in if it was selected.
  Future<void> deleteCustomPet(String petId);

  /// Replaces an existing custom pet's fields in place (e.g. a custom
  /// emoji's glyph or name), keeping its id. No-ops if [pet.id] doesn't
  /// match a known custom pet.
  Future<void> updateCustomPet(PetEntity pet);
}
