import '../entities/pet_entity.dart';
import '../repositories/pet_repository.dart';

class GetPets {
  const GetPets(this._repository);

  final PetRepository _repository;

  Future<List<PetEntity>> call() => _repository.getPets();
}
