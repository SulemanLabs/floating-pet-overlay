import 'package:flutter/material.dart';

import '../theme/app_radius.dart';

/// Lightweight shimmer sweep for skeleton loaders, built from a plain
/// [AnimationController] + gradient — no external package.
class AppShimmer extends StatefulWidget {
  const AppShimmer({super.key, this.width, this.height = 16, this.borderRadius = AppRadius.smRadius});

  final double? width;
  final double height;
  final BorderRadius borderRadius;

  @override
  State<AppShimmer> createState() => _AppShimmerState();
}

class _AppShimmerState extends State<AppShimmer> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.surfaceContainerHighest;
    final highlight = Theme.of(context).colorScheme.outlineVariant;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            final t = _controller.value;
            return LinearGradient(
              begin: Alignment(-1 - t * 2, 0),
              end: Alignment(1 - t * 2, 0),
              colors: [base, highlight, base],
              stops: const [0.35, 0.5, 0.65],
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(color: base, borderRadius: widget.borderRadius),
      ),
    );
  }
}

/// Skeleton placeholder for the Home hero card while overlay state loads.
class AppShimmerHeroCard extends StatelessWidget {
  const AppShimmerHeroCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const AppShimmer(width: 140, height: 140, borderRadius: BorderRadius.all(Radius.circular(70))),
        const SizedBox(height: 16),
        const AppShimmer(width: 120, height: 20),
        const SizedBox(height: 12),
        const AppShimmer(width: 80, height: 24, borderRadius: AppRadius.pillRadius),
        const SizedBox(height: 24),
        AppShimmer(width: double.infinity, height: 52, borderRadius: AppRadius.pillRadius),
      ],
    );
  }
}
