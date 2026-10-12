import 'package:shared_preferences/shared_preferences.dart';

/// Small on-device key-value storage for preferences.
class PreferencesService {
  PreferencesService({SharedPreferencesAsync? preferences})
    : _preferencesOverride = preferences;

  final SharedPreferencesAsync? _preferencesOverride;

  // Created on first use, so tests that never touch storage need no plugin.
  late final SharedPreferencesAsync _preferences =
      _preferencesOverride ?? SharedPreferencesAsync();

  Future<String?> getString(String key) => _preferences.getString(key);

  Future<void> setString(String key, String value) =>
      _preferences.setString(key, value);
}
