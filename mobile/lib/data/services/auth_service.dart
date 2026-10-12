import 'package:firebase_auth/firebase_auth.dart';

import '../../core/errors/app_exception.dart';
import '../../core/errors/error_mapper.dart';
import '../models/app_user.dart';

/// Wraps Firebase Auth so nothing above the data layer imports it. Every
/// failure leaves here as an [AppException].
class AuthService {
  AuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  /// Emits the current user on listen, then on sign-in, sign-out and profile
  /// changes, so a display name set after registration still arrives.
  Stream<AppUser?> userChanges() => _auth.userChanges().map(_toAppUser);

  AppUser? get currentUser => _toAppUser(_auth.currentUser);

  Future<String?> getIdToken({bool forceRefresh = false}) async {
    return _auth.currentUser?.getIdToken(forceRefresh);
  }

  Future<void> signIn({required String email, required String password}) {
    return _guard(
      () => _auth.signInWithEmailAndPassword(email: email, password: password),
    );
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) {
    return _guard(() async {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await credential.user?.updateDisplayName(name);
    });
  }

  Future<void> sendPasswordReset(String email) {
    return _guard(() => _auth.sendPasswordResetEmail(email: email));
  }

  Future<void> signOut() => _guard(_auth.signOut);

  Future<void> _guard(Future<void> Function() action) async {
    try {
      await action();
    } on FirebaseAuthException catch (error) {
      throw mapFirebaseAuthException(error);
    } on AppException {
      rethrow;
    } on Exception {
      throw const UnknownException();
    }
  }

  static AppUser? _toAppUser(User? user) {
    if (user == null) return null;
    return AppUser(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName,
    );
  }
}
