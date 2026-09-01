import '../../../../core/constants/app_constants.dart';
import '../../../../core/storage/local_storage.dart';
import '../../domain/entities/pet_entity.dart';
import '../models/pet_model.dart';

/// Built-in pets ship as emoji so the app has a working pet library with no
/// bundled binary assets. Custom PNG/GIF/Lottie import (Section 13) is a
/// follow-up — [PetType.image] and [PetType.gif] are already modeled to
/// support it without another migration.
const List<PetModel> _builtInPets = [
  PetModel(id: 'builtin_cat', name: 'Cat', type: PetType.emoji, emoji: '🐱', builtIn: true),
  PetModel(id: 'builtin_dog', name: 'Dog', type: PetType.emoji, emoji: '🐶', builtIn: true),
  PetModel(id: 'builtin_rabbit', name: 'Rabbit', type: PetType.emoji, emoji: '🐰', builtIn: true),
  PetModel(id: 'builtin_fox', name: 'Fox', type: PetType.emoji, emoji: '🦊', builtIn: true),
  PetModel(id: 'builtin_panda', name: 'Panda', type: PetType.emoji, emoji: '🐼', builtIn: true),
  PetModel(id: 'builtin_robot', name: 'Robot', type: PetType.emoji, emoji: '🤖', builtIn: true),
];

class PetLocalDataSource {
  PetLocalDataSource(this._storage);

  final LocalStorage _storage;

  static const _customPetsKey = 'pets.custom_list';
  static const _selectedPetIdKey = 'pets.selected_id';

  List<PetModel> get builtInPets => _builtInPets;

  List<PetModel> getCustomPets() {
    final raw = _storage.getString(_customPetsKey);
    if (raw == null || raw.isEmpty) return const [];
    try {
      return PetModel.decodeList(raw);
    } catch (_) {
      // Corrupted persisted data — fail safe rather than crash the pet library.
      return const [];
    }
  }

  Future<void> saveCustomPets(List<PetModel> pets) async {
    await _storage.setString(_customPetsKey, PetModel.encodeList(pets));
  }

  String getSelectedPetId() => _storage.getString(_selectedPetIdKey) ?? AppConstants.defaultPetId;

  Future<void> setSelectedPetId(String id) => _storage.setString(_selectedPetIdKey, id);
}
