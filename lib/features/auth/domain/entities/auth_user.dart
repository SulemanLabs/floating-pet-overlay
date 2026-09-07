/// The signed-in user's profile, as exposed by the auth feature to the rest
/// of the app. Deliberately a thin projection of Firebase's `User` — callers
/// outside this feature never touch `firebase_auth` types directly.
class AuthUser {
  const AuthUser({required this.uid, this.displayName, this.email, this.photoUrl});

  final String uid;
  final String? displayName;
  final String? email;
  final String? photoUrl;
}
