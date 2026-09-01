import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/pet_entity.dart';
import '../../domain/repositories/pet_repository.dart';
import '../datasources/pet_local_datasource.dart';
import '../models/pet_model.dart';

class PetRepositoryImpl implements PetRepository {
  PetRepositoryImpl(this._localDataSource);

  final PetLocalDataSource _localDataSource;

  @override
  Future<List<PetEntity>> getPets() async {
    return [..._localDataSource.builtInPets, ..._localDataSource.getCustomPets()];
  }

  @override
  Future<PetEntity> getSelectedPet() async {
    final pets = await getPets();
    final selectedId = _localDataSource.getSelectedPetId();
    return pets.firstWhere(
      (pet) => pet.id == selectedId,
      orElse: () => _localDataSource.builtInPets.first,
    );
  }

  @override
  Future<void> selectPet(String petId) => _localDataSource.setSelectedPetId(petId);

  @override
  Future<void> addCustomPet(PetEntity pet) async {
    final current = _localDataSource.getCustomPets();
    await _localDataSource.saveCustomPets([...current, PetModel.fromEntity(pet)]);
  }

  @override
  Future<void> deleteCustomPet(String petId) async {
    final current = _localDataSource.getCustomPets();
    await _localDataSource.saveCustomPets(current.where((pet) => pet.id != petId).toList());
    if (_localDataSource.getSelectedPetId() == petId) {
      await _localDataSource.setSelectedPetId(AppConstants.defaultPetId);
    }
  }

  @override
  Future<void> updateCustomPet(PetEntity pet) async {
    final current = _localDataSource.getCustomPets();
    final updated = current.map((existing) => existing.id == pet.id ? PetModel.fromEntity(pet) : existing).toList();
    await _localDataSource.saveCustomPets(updated);
  }
}
