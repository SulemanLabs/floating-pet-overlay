import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../domain/entities/onboarding_page_data.dart';
import '../providers/onboarding_providers.dart';

const _pages = [
  OnboardingPageData(
    icon: Icons.pets_rounded,
    title: 'Meet your floating companion',
    description: 'A tiny animated pet that lives right on your screen, drifting along on top of whatever app you\'re using.',
  ),
  OnboardingPageData(
    icon: Icons.local_fire_department_rounded,
    title: 'Grow your streaks',
    description: 'Start count-up or countdown streaks for the habits that matter, and keep the fire going one day at a time.',
  ),
  OnboardingPageData(
    icon: Icons.alarm_rounded,
    title: 'Never miss a deadline',
    description: 'Set task reminders and watch your pet\'s mood shift as a deadline gets close — a nudge you\'ll actually notice.',
  ),
  OnboardingPageData(
    icon: Icons.layers_rounded,
    title: 'Always in view',
    description: 'Your pet floats above any app, so your progress is never out of sight. Let\'s get you set up.',
  ),
];

/// First-run welcome flow — a swipeable set of slides that introduces the
/// floating pet, streaks, and task reminders before handing off to the
/// normal home screen. Shown once; [completeOnboarding] flips the persisted
/// flag that [appRouter]'s redirect checks on every launch.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _page = 0;

  bool get _isLastPage => _page == _pages.length - 1;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await completeOnboarding(ref);
    if (mounted) context.go(AppRoutes.home);
  }

  void _next() {
    if (_isLastPage) {
      _finish();
    } else {
      _pageController.nextPage(duration: const Duration(milliseconds: 320), curve: Curves.easeOutCubic);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(right: AppSpacing.base, top: AppSpacing.xs),
                child: AnimatedOpacity(
                  opacity: _isLastPage ? 0 : 1,
                  duration: const Duration(milliseconds: 200),
                  child: IgnorePointer(
                    ignoring: _isLastPage,
                    child: TextButton(onPressed: _finish, child: const Text('Skip')),
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) => setState(() => _page = index),
                itemBuilder: (context, index) => _OnboardingPage(data: _pages[index]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.base, AppSpacing.xl, AppSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < _pages.length; i++) _PageDot(active: i == _page),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  AppButton(label: _isLastPage ? 'Get started' : 'Next', onPressed: _next),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({required this.data});

  final OnboardingPageData data;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _FloatingIcon(icon: data.icon, color: colorScheme.primary, background: colorScheme.primaryContainer),
          const SizedBox(height: AppSpacing.xxl),
          Text(data.title, style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.base),
          Text(data.description, style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

/// A gentle, continuous up/down drift on the icon — a small callback to the
/// app's "floating pet" premise, rather than a static illustration.
class _FloatingIcon extends StatefulWidget {
  const _FloatingIcon({required this.icon, required this.color, required this.background});

  final IconData icon;
  final Color color;
  final Color background;

  @override
  State<_FloatingIcon> createState() => _FloatingIconState();
}

class _FloatingIconState extends State<_FloatingIcon> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat(reverse: true);

  late final Animation<double> _drift = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _drift,
      builder: (context, child) => Transform.translate(offset: Offset(0, -8 * _drift.value), child: child),
      child: Container(
        width: 160,
        height: 160,
        decoration: BoxDecoration(shape: BoxShape.circle, color: widget.background),
        child: Icon(widget.icon, size: 84, color: widget.color),
      ),
    );
  }
}

class _PageDot extends StatelessWidget {
  const _PageDot({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: active ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: active ? colorScheme.primary : colorScheme.surfaceContainerHighest,
        borderRadius: AppRadius.pillRadius,
      ),
    );
  }
}
