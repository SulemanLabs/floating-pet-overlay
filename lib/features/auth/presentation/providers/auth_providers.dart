import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSource(FirebaseAuth.instance, GoogleSignIn.instance);
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(ref.watch(authRemoteDataSourceProvider));
});

/// Live auth state, starting with the current session. `appRouter`'s
/// redirect reads `FirebaseAuth.instance.currentUser` directly instead (it's
/// a plain top-level value with no `ref`, same reasoning as the onboarding
/// flag) — this provider is for widgets that want to react to sign-in state.
final authStateProvider = StreamProvider<AuthUser?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
});

Future<AuthUser> signInWithGoogle(WidgetRef ref) {
  return ref.read(authRepositoryProvider).signInWithGoogle();
}

Future<void> signOut(WidgetRef ref) {
  return ref.read(authRepositoryProvider).signOut();
}
