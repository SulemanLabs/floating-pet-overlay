import 'package:flutter/material.dart';

import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

enum AppButtonVariant { primary, secondary, tertiary }

/// Unified button used across the app: consistent height, radius, and a
/// built-in loading state (spinner replaces the label, size stays fixed so
/// the button doesn't jump).
class AppButton extends StatefulWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool isLoading;

  /// Whether the button should fill the available width (the common case
  /// for form/screen actions). Set false for inline buttons.
  final bool expand;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _pressed = false;

  bool get _enabled => widget.onPressed != null && !widget.isLoading;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final spinnerColor = switch (widget.variant) {
      AppButtonVariant.primary => colorScheme.onPrimary,
      AppButtonVariant.secondary || AppButtonVariant.tertiary => colorScheme.primary,
    };

    final child = AnimatedSwitcher(
      duration: const Duration(milliseconds: 150),
      child: widget.isLoading
          ? SizedBox(
              key: const ValueKey('loading'),
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2.4, color: spinnerColor),
            )
          : Row(
              key: const ValueKey('label'),
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.icon != null) ...[Icon(widget.icon, size: 20), const SizedBox(width: AppSpacing.sm)],
                // Flexible so a long label in a width-constrained button (e.g.
                // two buttons side by side in Expanded slots) truncates
                // instead of overflowing the Row.
                Flexible(child: Text(widget.label, overflow: TextOverflow.ellipsis)),
              ],
            ),
    );

    final button = switch (widget.variant) {
      AppButtonVariant.primary => FilledButton(onPressed: _enabled ? widget.onPressed : null, child: child),
      AppButtonVariant.secondary => OutlinedButton(onPressed: _enabled ? widget.onPressed : null, child: child),
      AppButtonVariant.tertiary => TextButton(onPressed: _enabled ? widget.onPressed : null, child: child),
    };

    final sized = widget.expand ? SizedBox(width: double.infinity, child: button) : button;

    return GestureDetector(
      onTapDown: _enabled ? (_) => _setPressed(true) : null,
      onTapUp: _enabled ? (_) => _setPressed(false) : null,
      onTapCancel: _enabled ? () => _setPressed(false) : null,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: ClipRRect(borderRadius: AppRadius.pillRadius, child: sized),
      ),
    );
  }
}
