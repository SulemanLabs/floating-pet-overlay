import 'package:uuid/uuid.dart';

import '../../data/datasources/pet_asset_storage.dart';
import '../entities/pet_entity.dart';
import '../repositories/pet_repository.dart';

/// Full "Add Character" flow: validate the picked file, copy it into app
/// storage under a stable generated id, persist it as a custom pet.
///
/// Throws [AssetValidationFailure][../../../../core/errors/failures.dart]
/// (via [PetAssetStorage.validate]) if the file is invalid or corrupted —
/// the caller (the Add Character screen) is expected to catch and display it.
class ImportCustomPet {
  const ImportCustomPet(this._repository, this._assetStorage);

  final PetRepository _repository;
  final PetAssetStorage _assetStorage;

  Future<PetEntity> call({required String sourcePath, required String name}) async {
    final validated = await _assetStorage.validate(sourcePath);
    final id = const Uuid().v4();
    final storedPath = await _assetStorage.copyIntoAppStorage(sourcePath: sourcePath, petId: id);

    final pet = PetEntity(
      id: id,
      name: name.trim().isEmpty ? 'My Pet' : name.trim(),
      type: validated.type,
      assetPath: storedPath,
      builtIn: false,
      createdAt: DateTime.now(),
      width: validated.width,
      height: validated.height,
    );

    await _repository.addCustomPet(pet);
    return pet;
  }
}
