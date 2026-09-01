import 'package:flutter/material.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_text_field.dart';

/// Start-streak duration picker (spec §14). `duration == null` means "Until
/// I stop it" — an open-ended, count-up streak.
Future<void> showStreakDurationSelector(BuildContext context, {required Future<void> Function(Duration? duration) onSelect}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _StreakDurationSelectorSheet(onSelect: onSelect),
  );
}

const _presets = <(String, Duration?)>[
  ('Until I stop it', null),
  ('1 hour', Duration(hours: 1)),
  ('6 hours', Duration(hours: 6)),
  ('12 hours', Duration(hours: 12)),
  ('24 hours', Duration(hours: 24)),
  ('3 days', Duration(days: 3)),
  ('7 days', Duration(days: 7)),
  ('30 days', Duration(days: 30)),
];

class _StreakDurationSelectorSheet extends StatefulWidget {
  const _StreakDurationSelectorSheet({required this.onSelect});

  final Future<void> Function(Duration? duration) onSelect;

  @override
  State<_StreakDurationSelectorSheet> createState() => _StreakDurationSelectorSheetState();
}

class _StreakDurationSelectorSheetState extends State<_StreakDurationSelectorSheet> {
  bool _isSaving = false;

  Future<void> _choose(Duration? duration) async {
    setState(() => _isSaving = true);
    await widget.onSelect(duration);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _chooseCustom() async {
    final duration = await showDialog<Duration>(context: context, builder: (context) => const _CustomDurationDialog());
    if (duration != null) await _choose(duration);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.base, AppSpacing.sm, AppSpacing.base, AppSpacing.base),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Start streak', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Pick a duration for a countdown streak, or leave it open-ended and complete it yourself whenever you\'re done.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.base),
            if (_isSaving)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              for (final (label, duration) in _presets) _PresetTile(label: label, onTap: () => _choose(duration)),
              _PresetTile(label: 'Custom', icon: Icons.tune_rounded, onTap: _chooseCustom),
            ],
          ],
        ),
      ),
    );
  }
}

class _PresetTile extends StatelessWidget {
  const _PresetTile({required this.label, required this.onTap, this.icon});

  final String label;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      leading: Icon(icon ?? Icons.local_fire_department_rounded, color: Theme.of(context).colorScheme.primary),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}

class _CustomDurationDialog extends StatefulWidget {
  const _CustomDurationDialog();

  @override
  State<_CustomDurationDialog> createState() => _CustomDurationDialogState();
}

class _CustomDurationDialogState extends State<_CustomDurationDialog> {
  final _daysController = TextEditingController(text: '0');
  final _hoursController = TextEditingController(text: '1');

  @override
  void dispose() {
    _daysController.dispose();
    _hoursController.dispose();
    super.dispose();
  }

  void _submit() {
    final days = int.tryParse(_daysController.text) ?? 0;
    final hours = int.tryParse(_hoursController.text) ?? 0;
    final duration = Duration(days: days, hours: hours);
    if (duration <= Duration.zero) return;
    Navigator.of(context).pop(duration);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Custom duration'),
      content: Row(
        children: [
          Expanded(child: AppTextField(controller: _daysController, label: 'Days', keyboardType: TextInputType.number)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: AppTextField(controller: _hoursController, label: 'Hours', keyboardType: TextInputType.number)),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        TextButton(onPressed: _submit, child: const Text('Set duration')),
      ],
      shape: RoundedRectangleBorder(borderRadius: AppRadius.lgRadius),
    );
  }
}
