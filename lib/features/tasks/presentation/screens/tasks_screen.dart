import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/deadline_formatter.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../domain/entities/task_entity.dart';
import '../providers/task_providers.dart';
import '../widgets/add_task_sheet.dart';

/// Task list: the pet on the floating overlay reacts to whichever
/// incomplete task here has the soonest deadline (⏰ within an hour of it,
/// 🚨 once it's passed) — see `TaskController._syncNextDeadline` and
/// `DeadlineTicker.kt` for how that gets there.
class TasksScreen extends ConsumerWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(taskControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Task reminders')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showAddTaskSheet(
          context,
          onSubmit: (title, deadline) => ref.read(taskControllerProvider.notifier).addTask(title: title, deadline: deadline),
        ),
        icon: const Icon(Icons.add_alarm_rounded),
        label: const Text('New task'),
      ),
      body: tasksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('Failed to load tasks: $error')),
        data: (tasks) {
          if (tasks.isEmpty) {
            return const AppEmptyState(
              icon: Icons.checklist_rounded,
              title: 'No tasks yet',
              message: 'Add one with a deadline — your pet will start counting down and react as it gets close.',
            );
          }

          final next = nextDeadlineTask(tasks);
          final sorted = [...tasks]..sort((a, b) {
            if (a.isCompleted != b.isCompleted) return a.isCompleted ? 1 : -1;
            return a.deadline.compareTo(b.deadline);
          });

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(AppSpacing.base, AppSpacing.base, AppSpacing.base, AppSpacing.huge),
            itemCount: sorted.length,
            separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              final task = sorted[index];
              return _TaskTile(
                task: task,
                isNextDeadline: task.id == next?.id,
                onToggle: (value) => ref.read(taskControllerProvider.notifier).setCompleted(task, value ?? false),
                onDelete: () => ref.read(taskControllerProvider.notifier).deleteTask(task.id),
              );
            },
          );
        },
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  const _TaskTile({required this.task, required this.isNextDeadline, required this.onToggle, required this.onDelete});

  final TaskEntity task;
  final bool isNextDeadline;
  final ValueChanged<bool?> onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final subtitleColor = task.isOverdue ? colorScheme.error : null;
    final highlight = isNextDeadline && !task.isCompleted;

    return Dismissible(
      key: ValueKey(task.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        decoration: BoxDecoration(color: colorScheme.errorContainer, borderRadius: AppRadius.lgRadius),
        child: Icon(Icons.delete_outline_rounded, color: colorScheme.error),
      ),
      onDismissed: (_) => onDelete(),
      child: AppCard(
        padding: EdgeInsets.zero,
        color: highlight ? colorScheme.primaryContainer.withValues(alpha: 0.35) : null,
        child: CheckboxListTile(
          controlAffinity: ListTileControlAffinity.leading,
          value: task.isCompleted,
          onChanged: onToggle,
          title: Text(
            task.title,
            style: task.isCompleted ? const TextStyle(decoration: TextDecoration.lineThrough) : null,
          ),
          subtitle: Text(
            '${DateFormat('EEE, MMM d · HH:mm').format(task.deadline)}'
            '${task.isCompleted ? '' : ' — ${formatRelativeDeadline(task.deadline)}'}',
            style: TextStyle(color: subtitleColor),
          ),
          secondary: highlight
              ? Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: (task.isOverdue ? colorScheme.error : colorScheme.primary).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    task.isOverdue ? Icons.warning_amber_rounded : Icons.alarm_rounded,
                    color: task.isOverdue ? colorScheme.error : colorScheme.primary,
                    size: 18,
                  ),
                )
              : null,
        ),
      ),
    );
  }
}
