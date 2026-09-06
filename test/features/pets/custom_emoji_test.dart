import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:floating_streak/core/errors/failures.dart';
import 'package:floating_streak/core/storage/local_storage.dart';
import 'package:floating_streak/features/pets/data/datasources/pet_local_datasource.dart';
import 'package:floating_streak/features/pets/data/models/pet_model.dart';
import 'package:floating_streak/features/pets/data/repositories/pet_repository_impl.dart';
import 'package:floating_streak/features/pets/domain/entities/pet_entity.dart';
import 'package:floating_streak/features/pets/domain/usecases/add_custom_emoji.dart';
import 'package:floating_streak/features/pets/domain/usecases/delete_custom_pet.dart';
import 'package:floating_streak/features/pets/domain/usecases/update_custom_emoji.dart';
import 'package:floating_streak/features/pets/data/datasources/pet_asset_storage.dart';

void main() {
  late Directory tempDir;
  late Box<PetModel> petBox;
  late Box prefsBox;
  late LocalStorage storage;
  late PetRepositoryImpl repository;
  late AddCustomEmoji addCustomEmoji;
  late UpdateCustomEmoji updateCustomEmoji;

  setUpAll(() {
    if (!Hive.isAdapterRegistered(petModelTypeId)) {
      Hive.registerAdapter(PetModelAdapter());
    }
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('custom_emoji_hive_test');
    Hive.init(tempDir.path);
    petBox = await Hive.openBox<PetModel>('pets_test');
    prefsBox = await Hive.openBox('prefs_test');
    storage = LocalStorage(prefsBox);
    repository = PetRepositoryImpl(PetLocalDataSource(petBox, storage));
    addCustomEmoji = AddCustomEmoji(repository);
    updateCustomEmoji = UpdateCustomEmoji(repository);
  });

  tearDown(() async {
    if (petBox.isOpen) await petBox.close();
    if (prefsBox.isOpen) await prefsBox.close();
    await Hive.deleteBoxFromDisk('pets_test', path: tempDir.path);
    await Hive.deleteBoxFromDisk('prefs_test', path: tempDir.path);
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  group('AddCustomEmoji', () {
    test('creates a custom emoji pet with a generated id', () async {
      final pet = await addCustomEmoji.call(emoji: '🦊', name: 'My Fox');

      expect(pet.type, PetType.emoji);
      expect(pet.emoji, '🦊');
      expect(pet.name, 'My Fox');
      expect(pet.builtIn, isFalse);
      expect(pet.id, isNotEmpty);
      expect(pet.id, isNot('🦊'));
    });

    test('persists the custom emoji so it appears in getPets()', () async {
      final pet = await addCustomEmoji.call(emoji: '🐸', name: 'Froggy');

      final pets = await repository.getPets();
      expect(pets.map((p) => p.id), contains(pet.id));
    });

    test('reloads the custom emoji after the repository is recreated', () async {
      final pet = await addCustomEmoji.call(emoji: '🐸', name: 'Froggy');

      final freshRepository = PetRepositoryImpl(PetLocalDataSource(petBox, storage));
      final reloaded = await freshRepository.getPets();

      final found = reloaded.firstWhere((p) => p.id == pet.id);
      expect(found.emoji, '🐸');
      expect(found.name, 'Froggy');
    });

    test('falls back to a default name when the name is blank', () async {
      final pet = await addCustomEmoji.call(emoji: '🔥', name: '   ');
      expect(pet.name, isNotEmpty);
    });

    test('throws EmojiValidationFailure for an empty emoji', () async {
      expect(() => addCustomEmoji.call(emoji: '', name: 'Nothing'), throwsA(isA<EmojiValidationFailure>()));
    });

    test('throws EmojiValidationFailure for a whitespace-only emoji', () async {
      expect(() => addCustomEmoji.call(emoji: '   ', name: 'Nothing'), throwsA(isA<EmojiValidationFailure>()));
    });

    test('two custom pets with the same emoji get unique ids', () async {
      final first = await addCustomEmoji.call(emoji: '🦊', name: 'My Fox');
      final second = await addCustomEmoji.call(emoji: '🦊', name: 'Work Fox');

      expect(first.id, isNot(second.id));
      final pets = await repository.getPets();
      expect(pets.where((p) => !p.builtIn && p.emoji == '🦊').length, 2);
    });

    // Multi-codepoint emoji sequences (modifiers, ZWJ joins, variation
    // selectors) must round-trip as whole strings — never truncated to a
    // single Dart UTF-16 code unit.
    for (final glyph in ['😀', '👍', '👍🏽', '❤️', '❤️‍🔥', '👨‍💻', '👩‍🚀', '🐱‍👤']) {
      test('stores the full unicode sequence for $glyph unmodified', () async {
        final pet = await addCustomEmoji.call(emoji: glyph, name: 'Test');
        final freshRepository = PetRepositoryImpl(PetLocalDataSource(petBox, storage));
        final reloaded = await freshRepository.getPets();
        final found = reloaded.firstWhere((p) => p.id == pet.id);
        expect(found.emoji, glyph);
      });
    }
  });

  group('UpdateCustomEmoji', () {
    test('changes the emoji glyph of an existing custom pet', () async {
      final pet = await addCustomEmoji.call(emoji: '🦊', name: 'Fox');

      final updated = await updateCustomEmoji.call(existing: pet, emoji: '🤖', name: 'Fox');

      expect(updated.id, pet.id);
      expect(updated.emoji, '🤖');
      final pets = await repository.getPets();
      expect(pets.firstWhere((p) => p.id == pet.id).emoji, '🤖');
    });

    test('changes the name of an existing custom pet', () async {
      final pet = await addCustomEmoji.call(emoji: '🦊', name: 'Fox');

      final updated = await updateCustomEmoji.call(existing: pet, emoji: '🦊', name: 'Robot');

      expect(updated.name, 'Robot');
      final pets = await repository.getPets();
      expect(pets.firstWhere((p) => p.id == pet.id).name, 'Robot');
    });

    test('updates in place rather than creating a duplicate', () async {
      final pet = await addCustomEmoji.call(emoji: '🦊', name: 'Fox');
      await updateCustomEmoji.call(existing: pet, emoji: '🤖', name: 'Robot');

      final pets = await repository.getPets();
      expect(pets.where((p) => p.id == pet.id), hasLength(1));
    });

    test('throws EmojiValidationFailure when the new emoji is empty', () async {
      final pet = await addCustomEmoji.call(emoji: '🦊', name: 'Fox');
      expect(() => updateCustomEmoji.call(existing: pet, emoji: '', name: 'Fox'), throwsA(isA<EmojiValidationFailure>()));
    });

    test('throws EmojiValidationFailure for a built-in pet', () async {
      const builtIn = PetEntity(id: 'builtin_cat', name: 'Cat', type: PetType.emoji, emoji: '🐱', builtIn: true);
      expect(
        () => updateCustomEmoji.call(existing: builtIn, emoji: '🐶', name: 'Dog'),
        throwsA(isA<EmojiValidationFailure>()),
      );
    });
  });

  group('DeleteCustomPet with emoji pets', () {
    test('deletes a custom emoji pet and falls back the selection if it was active', () async {
      final pet = await addCustomEmoji.call(emoji: '🦊', name: 'Fox');
      await repository.selectPet(pet.id);

      await DeleteCustomPet(repository, PetAssetStorage()).call(pet);

      final pets = await repository.getPets();
      expect(pets.map((p) => p.id), isNot(contains(pet.id)));
      final selected = await repository.getSelectedPet();
      expect(selected.builtIn, isTrue);
    });
  });

  group('Selection', () {
    test('selecting a custom emoji pet updates the active pet', () async {
      final pet = await addCustomEmoji.call(emoji: '🦊', name: 'Fox');

      await repository.selectPet(pet.id);

      final selected = await repository.getSelectedPet();
      expect(selected.id, pet.id);
      expect(selected.emoji, '🦊');
    });
  });
}
