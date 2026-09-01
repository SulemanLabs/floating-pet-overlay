import '../entities/pet_entity.dart';
import '../repositories/pet_repository.dart';

class GetSelectedPet {
  const GetSelectedPet(this._repository);

  final PetRepository _repository;

  Future<PetEntity> call() => _repository.getSelectedPet();
}
