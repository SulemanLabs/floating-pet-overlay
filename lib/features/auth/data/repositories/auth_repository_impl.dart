import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._remote);

  final AuthRemoteDataSource _remote;

  @override
  Stream<AuthUser?> authStateChanges() => _remote.authStateChanges().map(_toAuthUser);

  @override
  AuthUser? get currentUser => _toAuthUser(_remote.currentUser);

  @override
  Future<AuthUser> signInWithGoogle() async {
    final user = await _remote.signInWithGoogle();
    return _toAuthUser(user)!;
  }

  @override
  Future<void> signOut() => _remote.signOut();

  AuthUser? _toAuthUser(User? user) {
    if (user == null) return null;
    return AuthUser(uid: user.uid, displayName: user.displayName, email: user.email, photoUrl: user.photoURL);
  }
}
