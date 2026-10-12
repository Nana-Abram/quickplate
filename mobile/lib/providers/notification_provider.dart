import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/errors/app_exception.dart';
import '../data/models/app_user.dart';
import '../data/models/push_message.dart';
import '../data/repositories/notification_repository.dart';

/// Keeps this device registered for order pushes while someone is signed in,
/// and passes incoming pushes on to the UI.
class NotificationProvider extends ChangeNotifier {
  NotificationProvider(this._repository);

  final NotificationRepository _repository;

  String? _userId;
  bool _permissionDenied = false;
  StreamSubscription<String>? _tokenRefresh;

  /// True once the user has declined notifications on this device.
  bool get permissionDenied => _permissionDenied;

  Stream<PushMessage> get onForegroundMessage =>
      _repository.onForegroundMessage;

  Stream<PushMessage> get onMessageOpenedApp => _repository.onMessageOpenedApp;

  Future<PushMessage?> getInitialMessage() => _repository.getInitialMessage();

  /// Called by the proxy provider on every session change. It runs during a
  /// build, so the async work is started here but never awaited.
  void onAuthChanged(AppUser? user) {
    if (user?.uid == _userId) return;
    final signedOut = _userId != null && user == null;
    _userId = user?.uid;

    unawaited(_tokenRefresh?.cancel());
    _tokenRefresh = null;

    if (user != null) {
      unawaited(_register());
    } else if (signedOut) {
      unawaited(_unregister());
    }
  }

  Future<void> _register() async {
    try {
      final registered = await _repository.registerDevice();
      _setPermissionDenied(!registered);
      if (!registered) return;
      _tokenRefresh = _repository.onTokenRefresh.listen(
        (token) => unawaited(_uploadQuietly(token)),
      );
    } on AppException catch (error) {
      // Pushes are a convenience: the tracking screen still updates live.
      debugPrint('Could not register for push notifications: $error');
    } on Exception catch (error) {
      debugPrint('Push notifications unavailable on this device: $error');
    }
  }

  Future<void> _uploadQuietly(String token) async {
    try {
      await _repository.uploadToken(token);
    } on AppException catch (error) {
      debugPrint('Could not upload refreshed push token: $error');
    }
  }

  Future<void> _unregister() async {
    try {
      await _repository.unregisterDevice();
    } on Exception catch (error) {
      debugPrint('Could not delete push token: $error');
    }
  }

  void _setPermissionDenied(bool denied) {
    if (_permissionDenied == denied) return;
    _permissionDenied = denied;
    notifyListeners();
  }

  @override
  void dispose() {
    unawaited(_tokenRefresh?.cancel());
    super.dispose();
  }
}
