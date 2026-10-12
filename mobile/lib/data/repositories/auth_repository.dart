import '../models/app_user.dart';
import '../services/auth_service.dart';

class AuthRepository {
  AuthRepository(this._authService);

  final AuthService _authService;

  Stream<AppUser?> userChanges() => _authService.userChanges();

  Future<void> signIn({required String email, required String password}) {
    return _authService.signIn(email: email.trim(), password: password);
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) {
    return _authService.register(
      name: name.trim(),
      email: email.trim(),
      password: password,
    );
  }

  Future<void> sendPasswordReset(String email) {
    return _authService.sendPasswordReset(email.trim());
  }

  Future<void> signOut() => _authService.signOut();
}
