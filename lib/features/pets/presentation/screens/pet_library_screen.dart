import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_confirm_dialog.dart';
import '../../../overlay/presentation/providers/overlay_providers.dart';
import '../../domain/entities/pet_entity.dart';
import '../providers/pet_providers.dart';
import '../widgets/pet_avatar.dart';

enum _AddPetChoice { emoji, file }

class PetLibraryScreen extends ConsumerWidget {
  const PetLibraryScreen({super.key});

  Future<void> _addCustomPet(BuildContext context, WidgetRef ref) async {
    final choice = await showModalBottomSheet<_AddPetChoice>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.base, 0, AppSpacing.base, AppSpacing.sm),
              child: Text('Choose pet type', style: Theme.of(sheetContext).textTheme.titleMedium),
            ),
            ListTile(
              leading: const Text('😀', style: TextStyle(fontSize: 28)),
              title: const Text('Emoji'),
              subtitle: const Text('Any emoji from your keyboard'),
              onTap: () => Navigator.of(sheetContext).pop(_AddPetChoice.emoji),
            ),
            ListTile(
              leading: const Icon(Icons.image_outlined, size: 28),
              title: const Text('Image, GIF, or Lottie'),
              subtitle: const Text('Import a file from your device'),
              onTap: () => Navigator.of(sheetContext).pop(_AddPetChoice.file),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
    if (choice == null || !context.mounted) return;

    final saved = choice == _AddPetChoice.emoji
        ? await context.push<bool>(AppRoutes.addEmojiPet)
        : await context.push<bool>(AppRoutes.addPet);
    if (saved == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pet added to your library.')));
    }
  }

  Future<void> _editEmojiPet(BuildContext context, WidgetRef ref, PetEntity pet) async {
    final saved = await context.push<bool>(AppRoutes.addEmojiPet, extra: pet);
    if (saved == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pet updated.')));
    }
  }

  Future<void> _deletePet(BuildContext context, WidgetRef ref, PetEntity pet) async {
    final confirmed = await showAppConfirmDialog(
      context,
      title: 'Delete "${pet.name}"?',
      message: 'This removes it from your pet library. This cannot be undone.',
      confirmLabel: 'Delete',
      isDestructive: true,
    );
    if (!confirmed) return;

    final wasSelected = ref.read(overlayControllerProvider).value?.selectedPet.id == pet.id;
    await ref.read(deleteCustomPetProvider).call(pet);
    ref.invalidate(petsListProvider);
    if (wasSelected) {
      await ref.read(overlayControllerProvider.notifier).selectPet(AppConstants.defaultPetId);
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pet deleted.')));
    }
  }

  static const _gridDelegate = SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 3,
    mainAxisSpacing: AppSpacing.md,
    crossAxisSpacing: AppSpacing.md,
    childAspectRatio: 0.85,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final petsAsync = ref.watch(petsListProvider);
    final overlayAsync = ref.watch(overlayControllerProvider);
    final selectedId = overlayAsync.value?.selectedPet.id;

    return Scaffold(
      appBar: AppBar(title: const Text('Pet library')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addCustomPet(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add custom pet'),
      ),
      body: petsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('Failed to load pets: $error')),
        data: (pets) {
          final builtIns = pets.where((pet) => pet.builtIn).toList();
          final customs = pets.where((pet) => !pet.builtIn).toList();

          Widget tileFor(PetEntity pet) {
            final isSelected = pet.id == selectedId;
            return _PetTile(
              pet: pet,
              isSelected: isSelected,
              onTap: () => ref.read(overlayControllerProvider.notifier).selectPet(pet.id),
              onEdit: pet.type == PetType.emoji && !pet.builtIn ? () => _editEmojiPet(context, ref, pet) : null,
              onDelete: pet.builtIn ? null : () => _deletePet(context, ref, pet),
            );
          }

          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.base, AppSpacing.base, AppSpacing.base, 0),
                sliver: SliverToBoxAdapter(child: _SectionHeader('Built-in')),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
                sliver: SliverGrid(
                  gridDelegate: _gridDelegate,
                  delegate: SliverChildBuilderDelegate((context, index) => tileFor(builtIns[index]), childCount: builtIns.length),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.base, AppSpacing.xl, AppSpacing.base, 0),
                sliver: SliverToBoxAdapter(child: _SectionHeader('Custom')),
              ),
              if (customs.isEmpty)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.base, AppSpacing.md, AppSpacing.base, 0),
                  sliver: SliverToBoxAdapter(
                    child: Text(
                      'No custom pets yet. Tap "Add custom pet" to create one.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
                  sliver: SliverGrid(
                    gridDelegate: _gridDelegate,
                    delegate: SliverChildBuilderDelegate((context, index) => tileFor(customs[index]), childCount: customs.length),
                  ),
                ),
              const SliverPadding(padding: EdgeInsets.only(bottom: AppSpacing.huge)),
            ],
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurfaceVariant),
    );
  }
}

class _PetTile extends StatelessWidget {
  const _PetTile({required this.pet, required this.isSelected, required this.onTap, this.onEdit, this.onDelete});

  final PetEntity pet;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: isSelected ? colorScheme.primaryContainer.withValues(alpha: 0.5) : colorScheme.surface,
      borderRadius: AppRadius.lgRadius,
      child: InkWell(
        borderRadius: AppRadius.lgRadius,
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: AppRadius.lgRadius,
            border: Border.all(color: isSelected ? colorScheme.primary : colorScheme.outlineVariant, width: isSelected ? 2 : 1),
          ),
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  PetAvatar(pet: pet, size: 56),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    pet.name,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600, color: colorScheme.onSurface),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              if (isSelected)
                Positioned(
                  top: -6,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(color: colorScheme.primary, shape: BoxShape.circle, border: Border.all(color: colorScheme.surface, width: 2)),
                      child: Icon(Icons.check_rounded, color: colorScheme.onPrimary, size: 13),
                    ),
                  ),
                ),
              if (onEdit != null)
                Positioned(
                  top: -8,
                  left: -8,
                  child: Material(
                    color: colorScheme.surface,
                    shape: CircleBorder(side: BorderSide(color: colorScheme.outlineVariant)),
                    elevation: 0,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: onEdit,
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(Icons.edit_outlined, size: 14, color: colorScheme.onSurfaceVariant),
                      ),
                    ),
                  ),
                ),
              if (onDelete != null)
                Positioned(
                  top: -8,
                  right: -8,
                  child: Material(
                    color: colorScheme.surface,
                    shape: CircleBorder(side: BorderSide(color: colorScheme.outlineVariant)),
                    elevation: 0,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: onDelete,
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(Icons.close_rounded, size: 14, color: colorScheme.onSurfaceVariant),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
