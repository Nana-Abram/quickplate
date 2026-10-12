import 'dart:async';

import 'package:flutter/material.dart';

import '../data/repositories/settings_repository.dart';

/// Holds the user's light/dark preference and remembers it on the device.
/// [initialMode] is read before the first frame, so the app never flashes the
/// wrong theme on launch.
class ThemeProvider extends ChangeNotifier {
  ThemeProvider(this._settings, {ThemeMode initialMode = ThemeMode.system})
    : _themeMode = initialMode;

  final SettingsRepository _settings;
  ThemeMode _themeMode;

  ThemeMode get themeMode => _themeMode;

  void setThemeMode(ThemeMode mode) {
    if (mode == _themeMode) return;
    _themeMode = mode;
    notifyListeners();
    unawaited(_save(mode));
  }

  Future<void> _save(ThemeMode mode) async {
    try {
      await _settings.saveThemeMode(mode);
    } on Exception catch (error) {
      // The new theme still applies; it just will not survive a restart.
      debugPrint('Could not save the theme: $error');
    }
  }
}
