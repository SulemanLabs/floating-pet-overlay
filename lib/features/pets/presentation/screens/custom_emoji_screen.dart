import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_banner.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_confirm_dialog.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../overlay/presentation/providers/overlay_providers.dart';
import '../../domain/entities/pet_entity.dart';
import '../providers/pet_providers.dart';

/// "Add Custom Emoji" / "Edit Custom Emoji" flow (Sections 5 and 20). One
/// screen serves both: pass [existingPet] to edit it in place, or omit it
/// to create a new custom emoji pet.
///
/// The emoji field is a plain [AppTextField] — the OS emoji keyboard (or a
/// pasted/typed Unicode string) supplies the glyph, so there's no custom
/// emoji picker to build or maintain (Section 23).
class CustomEmojiScreen extends ConsumerStatefulWidget {
  const CustomEmojiScreen({super.key, this.existingPet});

  final PetEntity? existingPet;

  @override
  ConsumerState<CustomEmojiScreen> createState() => _CustomEmojiScreenState();
}

class _CustomEmojiScreenState extends ConsumerState<CustomEmojiScreen> {
  late final _emojiController = TextEditingController(text: widget.existingPet?.emoji ?? '');
  late final _nameController = TextEditingController(text: widget.existingPet?.name ?? '');

  String _preview = '';
  String? _errorMessage;
  bool _isBusy = false;

  bool get _isEditing => widget.existingPet != null;

  @override
  void initState() {
    super.initState();
    _preview = _emojiController.text;
    _emojiController.addListener(() {
      if (_preview != _emojiController.text) setState(() => _preview = _emojiController.text);
    });
  }

  @override
  void dispose() {
    _emojiController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _isBusy = true;
      _errorMessage = null;
    });
    try {
      final existing = widget.existingPet;
      final saved = existing == null
          ? await ref.read(addCustomEmojiProvider).call(emoji: _emojiController.text, name: _nameController.text)
          : await ref
                .read(updateCustomEmojiProvider)
                .call(existing: existing, emoji: _emojiController.text, name: _nameController.text);

      ref.invalidate(petsListProvider);

      // If we just edited the pet that's currently active, refresh the
      // overlay's copy so the Flutter preview and native overlay pick up
      // the new glyph/name immediately (Section 9: no restart required).
      final activePetId = ref.read(overlayControllerProvider).value?.selectedPet.id;
      if (activePetId == saved.id) {
        await ref.read(overlayControllerProvider.notifier).selectPet(saved.id);
      } else if (existing == null) {
        // A brand-new pet, not yet active — offer to make it the floating
        // pet right away instead of requiring a separate trip to the
        // library to select it.
        if (!mounted) return;
        final setNow = await showAppConfirmDialog(
          context,
          title: 'Set as active pet?',
          message: 'Make "${saved.name}" your floating pet right now?',
          confirmLabel: 'Set now',
          cancelLabel: 'Not now',
        );
        if (setNow && mounted) {
          await ref.read(overlayControllerProvider.notifier).selectPet(saved.id);
        }
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on EmojiValidationFailure catch (e) {
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

  @override
  Widget build(BuildContext context) {
    final trimmedPreview = _preview.trim();

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit emoji pet' : 'Add custom emoji')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.base),
        children: [
          Text(
            'Type, paste, or use your keyboard\'s emoji picker to choose any Unicode emoji.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.xl),
          Center(child: _EmojiPreview(emoji: trimmedPreview)),
          const SizedBox(height: AppSpacing.xl),
          AppTextField(
            controller: _emojiController,
            label: 'Emoji',
            hint: 'e.g. 🦊',
            autofocus: !_isEditing,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(controller: _nameController, label: 'Pet name', hint: 'e.g. Fox'),
          if (_errorMessage != null) ...[
            const SizedBox(height: AppSpacing.base),
            AppBanner(title: 'Couldn\'t save that pet', message: _errorMessage!, variant: AppBannerVariant.error),
          ],
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Cancel',
                  variant: AppButtonVariant.secondary,
                  onPressed: _isBusy ? null : () => Navigator.of(context).pop(false),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: AppButton(label: 'Save', isLoading: _isBusy, onPressed: _save)),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmojiPreview extends StatelessWidget {
  const _EmojiPreview({required this.emoji});

  final String emoji;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: 120,
      height: 120,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colorScheme.primaryContainer,
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: emoji.isEmpty
          ? Icon(Icons.emoji_emotions_outlined, size: 48, color: colorScheme.onPrimaryContainer)
          : FittedBox(child: Text(emoji, style: const TextStyle(fontSize: 64))),
    );
  }
}
