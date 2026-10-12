import 'package:flutter/foundation.dart';

/// Values read from `mobile/.env` at startup.
@immutable
class AppConfig {
  const AppConfig({required this.apiBaseUrl});

  factory AppConfig.fromEnv(Map<String, String> env) {
    final apiBaseUrl = env['API_BASE_URL']?.trim() ?? '';
    if (apiBaseUrl.isEmpty) {
      throw StateError(
        'API_BASE_URL is missing. Copy mobile/.env.example to mobile/.env '
        '(see docs/MANUAL_SETUP.md).',
      );
    }
    return AppConfig(apiBaseUrl: apiBaseUrl);
  }

  final String apiBaseUrl;
}
