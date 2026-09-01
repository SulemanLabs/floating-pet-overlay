import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:floating_pet_overlay/core/storage/local_storage.dart';
import 'package:floating_pet_overlay/features/pets/data/datasources/pet_local_datasource.dart';
import 'package:floating_pet_overlay/features/pets/data/models/pet_model.dart';
import 'package:floating_pet_overlay/features/pets/data/repositories/pet_repository_impl.dart';
import 'package:floating_pet_overlay/features/pets/domain/entities/pet_entity.dart';

void main() {
  late LocalStorage storage;
  late PetRepositoryImpl repository;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storage = await LocalStorage.create();
    repository = PetRepositoryImpl(PetLocalDataSource(storage));
  });

  test('getPets returns all built-in pets when no custom pets exist', () async {
    final pets = await repository.getPets();

    expect(pets, isNotEmpty);
    expect(pets.every((pet) => pet.builtIn), isTrue);
  });

  test('getSelectedPet defaults to builtin_cat', () async {
    final selected = await repository.getSelectedPet();

    expect(selected.id, 'builtin_cat');
  });

  test('selectPet persists the choice across repository instances', () async {
    await repository.selectPet('builtin_fox');

    final freshRepository = PetRepositoryImpl(PetLocalDataSource(storage));
    final selected = await freshRepository.getSelectedPet();

    expect(selected.id, 'builtin_fox');
  });

  test('getSelectedPet falls back to the first built-in pet if the saved id no longer exists', () async {
    await repository.selectPet('deleted_custom_pet');

    final selected = await repository.getSelectedPet();

    expect(selected.builtIn, isTrue);
  });

  test('custom pets survive a JSON encode/decode round trip via the datasource', () async {
    final dataSource = PetLocalDataSource(storage);
    final custom = PetModel(
      id: 'custom_1',
      name: 'My Pet',
      type: PetType.emoji,
      emoji: '🐸',
      builtIn: false,
      createdAt: DateTime(2026, 1, 1),
    );

    await dataSource.saveCustomPets([custom]);
    final reloaded = PetLocalDataSource(storage).getCustomPets();

    expect(reloaded, hasLength(1));
    expect(reloaded.single.id, 'custom_1');
    expect(reloaded.single.emoji, '🐸');
  });

  test('addCustomPet appends the pet to getPets()', () async {
    const custom = PetEntity(
      id: 'custom_frog',
      name: 'Froggy',
      type: PetType.image,
      assetPath: '/tmp/froggy.png',
      builtIn: false,
      width: 128,
      height: 128,
    );

    await repository.addCustomPet(custom);
    final pets = await repository.getPets();

    expect(pets.map((p) => p.id), contains('custom_frog'));
    final saved = pets.firstWhere((p) => p.id == 'custom_frog');
    expect(saved.width, 128);
    expect(saved.assetPath, '/tmp/froggy.png');
  });

  test('deleteCustomPet removes the pet and falls back the selection if it was active', () async {
    const custom = PetEntity(id: 'custom_frog', name: 'Froggy', type: PetType.image, builtIn: false);
    await repository.addCustomPet(custom);
    await repository.selectPet('custom_frog');

    await repository.deleteCustomPet('custom_frog');

    final pets = await repository.getPets();
    expect(pets.map((p) => p.id), isNot(contains('custom_frog')));

    final selected = await repository.getSelectedPet();
    expect(selected.id, 'builtin_cat');
  });

  test('deleteCustomPet leaves the selection untouched if a different pet was active', () async {
    const custom = PetEntity(id: 'custom_frog', name: 'Froggy', type: PetType.image, builtIn: false);
    await repository.addCustomPet(custom);
    await repository.selectPet('builtin_fox');

    await repository.deleteCustomPet('custom_frog');

    final selected = await repository.getSelectedPet();
    expect(selected.id, 'builtin_fox');
  });
}
