import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart' as lottie;
import 'package:path/path.dart' as p;

import '../../../../core/errors/failures.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_banner.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../data/datasources/pet_asset_storage.dart';
import '../../domain/entities/pet_entity.dart';
import '../providers/pet_providers.dart';

/// "Add Character" flow (Section 13): pick a file, validate it, preview it,
/// name it, save it. Only touches the picker's temp path for the preview —
/// the actual copy into app storage happens inside `ImportCustomPet`, only
/// once the user taps Save.
class AddPetScreen extends ConsumerStatefulWidget {
  const AddPetScreen({super.key});

  @override
  ConsumerState<AddPetScreen> createState() => _AddPetScreenState();
}

class _AddPetScreenState extends ConsumerState<AddPetScreen> {
  static const _allowedExtensions = ['png', 'jpg', 'jpeg', 'webp', 'gif', 'json'];

  final _nameController = TextEditingController();

  String? _pickedPath;
  PetAssetValidationResult? _validation;
  String? _errorMessage;
  bool _isBusy = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    setState(() {
      _errorMessage = null;
      _isBusy = true;
    });
    try {
      final picked = await FilePicker.pickFile(type: FileType.custom, allowedExtensions: _allowedExtensions);
      final path = picked?.path;
      if (path == null) {
        setState(() => _isBusy = false);
        return; // user cancelled the picker
      }

      final validation = await ref.read(petAssetStorageProvider).validate(path);
      setState(() {
        _pickedPath = path;
        _validation = validation;
        _isBusy = false;
        if (_nameController.text.isEmpty) {
          _nameController.text = _suggestedName(path);
        }
      });
    } on AssetValidationFailure catch (e) {
      setState(() {
        _pickedPath = null;
        _validation = null;
        _errorMessage = e.message;
        _isBusy = false;
      });
    } catch (e) {
      setState(() {
        _pickedPath = null;
        _validation = null;
        _errorMessage = 'Could not read that file: $e';
        _isBusy = false;
      });
    }
  }

  Future<void> _save() async {
    final path = _pickedPath;
    if (path == null) return;

    setState(() {
      _isBusy = true;
      _errorMessage = null;
    });
    try {
      await ref.read(importCustomPetProvider).call(sourcePath: path, name: _nameController.text);
      ref.invalidate(petsListProvider);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on AssetValidationFailure catch (e) {
      setState(() {
        _errorMessage = e.message;
        _isBusy = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Could not save this pet: $e';
        _isBusy = false;
      });
    }
  }

  String _suggestedName(String path) {
    final base = p.basenameWithoutExtension(path).replaceAll(RegExp(r'[_\-]+'), ' ').trim();
    if (base.isEmpty) return 'My Pet';
    return base
        .split(' ')
        .map((word) => word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final hasPreview = _pickedPath != null && _validation != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Add character')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.base),
        children: [
          Text(
            'Import a PNG, JPG, WebP, GIF, or Lottie JSON animation to use as your floating pet.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.base),
          Center(
            child: hasPreview
                ? _Preview(path: _pickedPath!, type: _validation!.type)
                : _DropZone(isBusy: _isBusy, onTap: _pickFile),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: AppSpacing.base),
            AppBanner(title: 'Couldn\'t import that file', message: _errorMessage!, variant: AppBannerVariant.error),
          ],
          if (hasPreview) ...[
            const SizedBox(height: AppSpacing.xl),
            AppTextField(controller: _nameController, label: 'Name'),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: 'Choose a different file',
              icon: Icons.refresh_rounded,
              variant: AppButtonVariant.secondary,
              onPressed: _isBusy ? null : _pickFile,
            ),
            const SizedBox(height: AppSpacing.xl),
            AppButton(label: 'Save', isLoading: _isBusy, onPressed: _save),
          ],
        ],
      ),
    );
  }
}

class _DropZone extends StatelessWidget {
  const _DropZone({required this.isBusy, required this.onTap});

  final bool isBusy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: AppRadius.lgRadius,
      onTap: isBusy ? null : onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl, horizontal: AppSpacing.base),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer.withValues(alpha: 0.35),
          borderRadius: AppRadius.lgRadius,
          border: Border.all(color: colorScheme.primary.withValues(alpha: 0.4), width: 1.5, style: BorderStyle.solid),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.upload_file_rounded, size: 36, color: colorScheme.primary),
            const SizedBox(height: AppSpacing.sm),
            Text(
              isBusy ? 'Reading file…' : 'Tap to choose a file',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(color: colorScheme.primary),
            ),
          ],
        ),
      ),
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview({required this.path, required this.type});

  final String path;
  final PetType type;

  @override
  Widget build(BuildContext context) {
    final child = type == PetType.lottie
        ? lottie.Lottie.file(File(path), width: 160, height: 160, fit: BoxFit.contain)
        : Image.file(File(path), width: 160, height: 160, fit: BoxFit.contain);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: SizedBox(width: 160, height: 160, child: Center(child: child)),
    );
  }
}
