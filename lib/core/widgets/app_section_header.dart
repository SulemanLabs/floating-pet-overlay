import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// Small uppercase-weight label used to introduce a group of settings or
/// content. Shared so every screen's section titles look identical.
class AppSectionHeader extends StatelessWidget {
  const AppSectionHeader(this.label, {super.key, this.padding = const EdgeInsets.fromLTRB(4, 0, 4, AppSpacing.sm)});

  final String label;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Theme.of(context).colorScheme.primary),
      ),
    );
  }
}
