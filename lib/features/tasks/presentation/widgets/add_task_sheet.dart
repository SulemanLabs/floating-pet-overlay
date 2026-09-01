import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';

Future<void> showAddTaskSheet(BuildContext context, {required Future<void> Function(String title, DateTime deadline) onSubmit}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _AddTaskSheet(onSubmit: onSubmit),
  );
}

class _AddTaskSheet extends StatefulWidget {
  const _AddTaskSheet({required this.onSubmit});

  final Future<void> Function(String title, DateTime deadline) onSubmit;

  @override
  State<_AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<_AddTaskSheet> {
  final _titleController = TextEditingController();
  DateTime? _deadline;
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _deadline ?? now.add(const Duration(hours: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_deadline ?? now.add(const Duration(hours: 1))),
    );
    if (time == null || !mounted) return;

    setState(() => _deadline = DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  Future<void> _save() async {
    final deadline = _deadline;
    if (_titleController.text.trim().isEmpty || deadline == null) return;

    setState(() => _isSaving = true);
    await widget.onSubmit(_titleController.text, deadline);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final canSave = _titleController.text.trim().isNotEmpty && _deadline != null && !_isSaving;

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.base,
        right: AppSpacing.base,
        top: AppSpacing.sm,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.base,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('New task', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.base),
          AppTextField(
            controller: _titleController,
            label: 'Title',
            autofocus: true,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: _deadline == null ? 'Pick deadline' : DateFormat('EEE, MMM d · HH:mm').format(_deadline!),
            icon: Icons.event_rounded,
            variant: AppButtonVariant.secondary,
            onPressed: _pickDeadline,
          ),
          const SizedBox(height: AppSpacing.xl),
          AppButton(label: 'Save', isLoading: _isSaving, onPressed: canSave ? _save : null),
        ],
      ),
    );
  }
}
