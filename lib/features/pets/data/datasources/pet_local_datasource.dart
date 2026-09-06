import 'package:hive/hive.dart';

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

/// Custom pets live in the `pets` Hive box (mirroring `StreakLocalDataSource`
/// and `TaskLocalDataSource`); the selected pet id is just a scalar, so it
/// stays in the shared `prefs` box via [LocalStorage].
class PetLocalDataSource {
  PetLocalDataSource(this._box, this._storage);

  final Box<PetModel> _box;
  final LocalStorage _storage;

  static const _selectedPetIdKey = 'pets.selected_id';

  List<PetModel> get builtInPets => _builtInPets;

  List<PetModel> getCustomPets() {
    final pets = <PetModel>[];
    for (final key in _box.keys) {
      try {
        final model = _box.get(key);
        if (model != null) pets.add(model);
      } catch (_) {
        // A single corrupted record must not take down the whole pet library.
        continue;
      }
    }
    return pets;
  }

  Future<void> saveCustomPets(List<PetModel> pets) async {
    await _box.clear();
    await _box.putAll({for (final pet in pets) pet.id: pet});
  }

  String getSelectedPetId() => _storage.getString(_selectedPetIdKey) ?? AppConstants.defaultPetId;

  Future<void> setSelectedPetId(String id) => _storage.setString(_selectedPetIdKey, id);
}
