import '../../data/datasources/pet_asset_storage.dart';
import '../entities/pet_entity.dart';
import '../repositories/pet_repository.dart';

class DeleteCustomPet {
  const DeleteCustomPet(this._repository, this._assetStorage);

  final PetRepository _repository;
  final PetAssetStorage _assetStorage;

  Future<void> call(PetEntity pet) async {
    if (pet.builtIn) return; // safety net: built-in pets are never deletable from the UI anyway
    await _repository.deleteCustomPet(pet.id);
    final assetPath = pet.assetPath;
    if (assetPath != null) {
      await _assetStorage.deleteAsset(assetPath);
    }
  }
}
