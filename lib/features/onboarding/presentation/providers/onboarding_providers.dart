import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../data/datasources/onboarding_local_datasource.dart';

final onboardingLocalDataSourceProvider = Provider<OnboardingLocalDataSource>((ref) {
  return OnboardingLocalDataSource(ref.watch(localStorageProvider));
});

/// Marks onboarding as finished so it never shows again. Read directly by
/// the screen — a single one-shot write doesn't need a controller/notifier.
Future<void> completeOnboarding(WidgetRef ref) {
  return ref.read(onboardingLocalDataSourceProvider).markCompleted();
}
