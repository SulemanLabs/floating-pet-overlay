import '../entities/auth_user.dart';

abstract class AuthRepository {
  /// Emits the signed-in user (or `null` when signed out) on every auth
  /// state change, starting with the current state.
  Stream<AuthUser?> authStateChanges();

  AuthUser? get currentUser;

  /// Runs the Google sign-in flow and exchanges the resulting Google
  /// credential for a Firebase session. Throws if the user cancels the
  /// picker or the exchange fails.
  Future<AuthUser> signInWithGoogle();

  Future<void> signOut();
}
