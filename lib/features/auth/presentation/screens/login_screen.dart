import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../providers/auth_providers.dart';

/// Auth gate shown whenever there's no signed-in Firebase user (see
/// `appRouter`'s redirect). Signing in flips `FirebaseAuth.authStateChanges`,
/// which the router listens to directly, so there's no explicit navigation
/// on success — the redirect takes over as soon as the stream fires.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isSigningIn = false;
  String? _error;

  Future<void> _signIn() async {
    setState(() {
      _isSigningIn = true;
      _error = null;
    });
    try {
      await signInWithGoogle(ref);
    } catch (_) {
      if (mounted) setState(() => _error = "Couldn't sign in — please try again.");
    } finally {
      if (mounted) setState(() => _isSigningIn = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(shape: BoxShape.circle, color: colorScheme.primaryContainer),
                child: Icon(Icons.pets_rounded, size: 64, color: colorScheme.primary),
              ),
              const SizedBox(height: AppSpacing.xxl),
              Text('Welcome back', style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.base),
              Text(
                'Sign in to keep your floating pet, streaks, and tasks with you.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xxxl),
              AppButton(
                label: 'Continue with Google',
                icon: Icons.login_rounded,
                variant: AppButtonVariant.secondary,
                isLoading: _isSigningIn,
                onPressed: _signIn,
              ),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.base),
                Text(_error!, style: TextStyle(color: colorScheme.error), textAlign: TextAlign.center),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
