import 'package:firebase_auth/firebase_auth.dart';

import '../models/app_user.dart';

/// Wraps Firebase Auth so nothing above the data layer imports it.
class AuthService {
  AuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  /// Emits the current user on listen, then on every sign-in and sign-out.
  Stream<AppUser?> authStateChanges() =>
      _auth.authStateChanges().map(_toAppUser);

  AppUser? get currentUser => _toAppUser(_auth.currentUser);

  Future<String?> getIdToken({bool forceRefresh = false}) async {
    return _auth.currentUser?.getIdToken(forceRefresh);
  }

  Future<void> signOut() => _auth.signOut();

  static AppUser? _toAppUser(User? user) {
    if (user == null) return null;
    return AppUser(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName,
    );
  }
}
