import 'package:flutter/material.dart';

import '../services/preferences_service.dart';

/// Device-level settings that should survive a restart.
class SettingsRepository {
  SettingsRepository(this._preferences);

  final PreferencesService _preferences;

  static const String _themeModeKey = 'themeMode';

  /// The saved theme, or [ThemeMode.system] if none was saved or storage
  /// cannot be read. A broken preference must never stop the app starting.
  Future<ThemeMode> loadThemeMode() async {
    try {
      final saved = await _preferences.getString(_themeModeKey);
      return ThemeMode.values.asNameMap()[saved] ?? ThemeMode.system;
    } on Exception {
      return ThemeMode.system;
    }
  }

  Future<void> saveThemeMode(ThemeMode mode) =>
      _preferences.setString(_themeModeKey, mode.name);
}
