import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/models/app_user.dart';
import '../data/repositories/auth_repository.dart';

enum AuthStatus {
  /// Firebase has not reported the restored session yet; the splash shows.
  unknown,
  signedIn,
  signedOut,
}

/// Session state for the whole app. The router listens to it to redirect
/// between the auth screens and the rest of the app.
class AuthProvider extends ChangeNotifier {
  AuthProvider(this._repository) {
    _subscription = _repository.authStateChanges().listen(_onUserChanged);
  }

  final AuthRepository _repository;
  late final StreamSubscription<AppUser?> _subscription;

  AuthStatus _status = AuthStatus.unknown;
  AppUser? _user;

  AuthStatus get status => _status;
  AppUser? get user => _user;

  void _onUserChanged(AppUser? user) {
    final status = user == null ? AuthStatus.signedOut : AuthStatus.signedIn;
    if (status == _status && user == _user) return;
    _user = user;
    _status = status;
    notifyListeners();
  }

  Future<void> signOut() => _repository.signOut();

  @override
  void dispose() {
    unawaited(_subscription.cancel());
    super.dispose();
  }
}
