import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickplate/providers/theme_provider.dart';

void main() {
  group('ThemeProvider', () {
    test('follows the system by default', () {
      expect(ThemeProvider().themeMode, ThemeMode.system);
    });

    test('notifies only when the mode actually changes', () {
      final provider = ThemeProvider();
      var notifications = 0;
      provider.addListener(() => notifications++);

      provider
        ..setThemeMode(ThemeMode.dark)
        ..setThemeMode(ThemeMode.dark);

      expect(provider.themeMode, ThemeMode.dark);
      expect(notifications, 1);
    });
  });
}
