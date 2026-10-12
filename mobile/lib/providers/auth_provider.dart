import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/errors/app_exception.dart';
import '../data/models/app_user.dart';
import '../data/repositories/auth_repository.dart';
import 'view_state.dart';

enum AuthStatus {
  /// Firebase has not reported the restored session yet; the splash shows.
  unknown,
  signedIn,
  signedOut,
}

/// Session state for the whole app, plus the state of the current auth form
/// action (sign in, register, reset). The router listens to it to redirect
/// between the auth screens and the rest of the app.
class AuthProvider extends ChangeNotifier {
  AuthProvider(this._repository) {
    _subscription = _repository.userChanges().listen(_onUserChanged);
  }

  final AuthRepository _repository;
  late final StreamSubscription<AppUser?> _subscription;

  AuthStatus _status = AuthStatus.unknown;
  AppUser? _user;
  ViewState _actionState = ViewState.idle;
  String? _errorMessage;

  AuthStatus get status => _status;
  AppUser? get user => _user;

  /// State of the last sign-in, register, reset or sign-out call.
  ViewState get actionState => _actionState;
  bool get isBusy => _actionState == ViewState.loading;

  /// User-facing message for the last failed action.
  String? get errorMessage => _errorMessage;

  void _onUserChanged(AppUser? user) {
    final status = user == null ? AuthStatus.signedOut : AuthStatus.signedIn;
    if (status == _status && user == _user) return;
    _user = user;
    _status = status;
    notifyListeners();
  }

  Future<bool> signIn({required String email, required String password}) {
    return _run(() => _repository.signIn(email: email, password: password));
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) {
    return _run(
      () => _repository.register(name: name, email: email, password: password),
    );
  }

  Future<bool> sendPasswordReset(String email) {
    return _run(() => _repository.sendPasswordReset(email));
  }

  Future<bool> signOut() => _run(_repository.signOut);

  /// Clears a previous result so a newly opened form starts clean.
  void resetActionState() {
    if (_actionState == ViewState.idle && _errorMessage == null) return;
    _actionState = ViewState.idle;
    _errorMessage = null;
    notifyListeners();
  }

  /// Runs one auth action, tracking loading and error state. Returns whether
  /// it succeeded; navigation after success is driven by the session stream.
  Future<bool> _run(Future<void> Function() action) async {
    if (isBusy) return false;
    _actionState = ViewState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      await action();
      _actionState = ViewState.success;
      return true;
    } on AppException catch (error) {
      _errorMessage = error.message;
      _actionState = ViewState.error;
      return false;
    } finally {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    unawaited(_subscription.cancel());
    super.dispose();
  }
}
