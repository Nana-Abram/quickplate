import '../models/app_user.dart';
import '../services/auth_service.dart';

class AuthRepository {
  AuthRepository(this._authService);

  final AuthService _authService;

  Stream<AppUser?> authStateChanges() => _authService.authStateChanges();

  Future<void> signOut() => _authService.signOut();
}
