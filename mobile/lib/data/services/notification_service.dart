import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../models/push_message.dart';

/// Wraps Firebase Cloud Messaging so nothing above the data layer imports it.
class NotificationService {
  NotificationService({FirebaseMessaging? messaging})
    : _messagingOverride = messaging;

  final FirebaseMessaging? _messagingOverride;

  // Resolved lazily so the service can be constructed before Firebase is
  // ready, and never touched in tests that do not need it.
  FirebaseMessaging get _messaging =>
      _messagingOverride ?? FirebaseMessaging.instance;

  /// Asks to show notifications. On Android 13+ this is the runtime
  /// POST_NOTIFICATIONS prompt; older Android versions grant it at install.
  Future<bool> requestPermission() async {
    final settings = await _messaging.requestPermission();
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  Future<String?> getToken() => _messaging.getToken();

  Stream<String> get onTokenRefresh => _messaging.onTokenRefresh;

  /// Invalidates this device's token, so a signed-out phone stops receiving
  /// the previous user's order updates.
  Future<void> deleteToken() => _messaging.deleteToken();

  /// Pushes that arrive while the app is open. Android does not show these
  /// in the tray, so the app shows them itself.
  Stream<PushMessage> get onForegroundMessage =>
      FirebaseMessaging.onMessage.map(toPushMessage);

  /// Taps on a notification while the app was in the background.
  Stream<PushMessage> get onMessageOpenedApp =>
      FirebaseMessaging.onMessageOpenedApp.map(toPushMessage);

  /// The notification that launched the app from a terminated state, if any.
  Future<PushMessage?> getInitialMessage() async {
    final message = await _messaging.getInitialMessage();
    return message == null ? null : toPushMessage(message);
  }

  @visibleForTesting
  static PushMessage toPushMessage(RemoteMessage message) {
    return PushMessage(
      messageId: message.messageId,
      title: message.notification?.title,
      body: message.notification?.body,
      orderId: message.data['orderId'] as String?,
    );
  }
}
