import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../data/datasources/pet_asset_storage.dart';
import '../../data/datasources/pet_local_datasource.dart';
import '../../data/repositories/pet_repository_impl.dart';
import '../../domain/entities/pet_entity.dart';
import '../../domain/repositories/pet_repository.dart';
import '../../domain/usecases/add_custom_emoji.dart';
import '../../domain/usecases/delete_custom_pet.dart';
import '../../domain/usecases/get_pets.dart';
import '../../domain/usecases/get_selected_pet.dart';
import '../../domain/usecases/import_custom_pet.dart';
import '../../domain/usecases/select_pet.dart';
import '../../domain/usecases/update_custom_emoji.dart';

final petLocalDataSourceProvider = Provider<PetLocalDataSource>((ref) {
  return PetLocalDataSource(ref.watch(petHiveBoxProvider), ref.watch(localStorageProvider));
});

final petAssetStorageProvider = Provider<PetAssetStorage>((ref) => PetAssetStorage());

final petRepositoryProvider = Provider<PetRepository>((ref) {
  return PetRepositoryImpl(ref.watch(petLocalDataSourceProvider));
});

final getPetsProvider = Provider<GetPets>((ref) => GetPets(ref.watch(petRepositoryProvider)));

final getSelectedPetProvider = Provider<GetSelectedPet>((ref) => GetSelectedPet(ref.watch(petRepositoryProvider)));

final selectPetUseCaseProvider = Provider<SelectPet>((ref) => SelectPet(ref.watch(petRepositoryProvider)));

final importCustomPetProvider = Provider<ImportCustomPet>((ref) {
  return ImportCustomPet(ref.watch(petRepositoryProvider), ref.watch(petAssetStorageProvider));
});

final deleteCustomPetProvider = Provider<DeleteCustomPet>((ref) {
  return DeleteCustomPet(ref.watch(petRepositoryProvider), ref.watch(petAssetStorageProvider));
});

final addCustomEmojiProvider = Provider<AddCustomEmoji>((ref) => AddCustomEmoji(ref.watch(petRepositoryProvider)));

final updateCustomEmojiProvider = Provider<UpdateCustomEmoji>((ref) {
  return UpdateCustomEmoji(ref.watch(petRepositoryProvider));
});

/// The pet library list (built-in + custom). Refresh with
/// `ref.invalidate(petsListProvider)` after adding/removing a custom pet.
final petsListProvider = FutureProvider<List<PetEntity>>((ref) {
  return ref.watch(getPetsProvider).call();
});
