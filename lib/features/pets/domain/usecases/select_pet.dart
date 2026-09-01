import '../repositories/pet_repository.dart';

class SelectPet {
  const SelectPet(this._repository);

  final PetRepository _repository;

  Future<void> call(String petId) => _repository.selectPet(petId);
}
