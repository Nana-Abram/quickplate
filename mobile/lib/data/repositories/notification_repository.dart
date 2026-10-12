import '../models/push_message.dart';
import '../services/device_api_service.dart';
import '../services/notification_service.dart';

class NotificationRepository {
  NotificationRepository(this._notifications, this._deviceApi);

  final NotificationService _notifications;
  final DeviceApiService _deviceApi;

  /// Asks for permission and sends this device's token to the backend.
  /// Returns false if the user declined notifications.
  Future<bool> registerDevice() async {
    if (!await _notifications.requestPermission()) return false;
    final token = await _notifications.getToken();
    if (token == null) return false;
    await _deviceApi.registerToken(token);
    return true;
  }

  Future<void> uploadToken(String token) => _deviceApi.registerToken(token);

  Future<void> unregisterDevice() => _notifications.deleteToken();

  Stream<String> get onTokenRefresh => _notifications.onTokenRefresh;

  Stream<PushMessage> get onForegroundMessage =>
      _notifications.onForegroundMessage;

  Stream<PushMessage> get onMessageOpenedApp =>
      _notifications.onMessageOpenedApp;

  Future<PushMessage?> getInitialMessage() =>
      _notifications.getInitialMessage();
}
