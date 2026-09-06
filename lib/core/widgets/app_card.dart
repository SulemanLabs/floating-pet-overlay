import 'package:flutter/material.dart';

import '../theme/app_radius.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';

/// Standard surface used for grouped content: rounded corners and a thin
/// border, with only a very subtle neutral shadow (never raw Material
/// elevation) — cards should read as gently separated content, not
/// floating panels.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.base),
    this.color,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardTheme = theme.cardTheme;

    final content = Container(
      decoration: BoxDecoration(
        color: color ?? cardTheme.color,
        borderRadius: AppRadius.lgRadius,
        border: Border.all(color: theme.colorScheme.outlineVariant),
        boxShadow: AppShadows.forBrightness(theme.brightness),
      ),
      child: ClipRRect(
        borderRadius: AppRadius.lgRadius,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );

    return content;
  }
}
