import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quickplate/providers/theme_provider.dart';

import '../helpers/mocks.dart';

void main() {
  late MockSettingsRepository settings;

  setUpAll(() => registerFallbackValue(ThemeMode.system));

  setUp(() {
    settings = MockSettingsRepository();
    when(() => settings.saveThemeMode(any())).thenAnswer((_) async {});
  });

  group('ThemeProvider', () {
    test('starts with the mode read at launch', () {
      final provider = ThemeProvider(settings, initialMode: ThemeMode.dark);

      expect(provider.themeMode, ThemeMode.dark);
    });

    test('follows the system when nothing was saved', () {
      expect(ThemeProvider(settings).themeMode, ThemeMode.system);
    });

    test('saves a new mode and notifies once', () async {
      final provider = ThemeProvider(settings);
      var notifications = 0;
      provider.addListener(() => notifications++);

      provider
        ..setThemeMode(ThemeMode.light)
        ..setThemeMode(ThemeMode.light);
      await pumpEventQueue();

      expect(provider.themeMode, ThemeMode.light);
      expect(notifications, 1);
      verify(() => settings.saveThemeMode(ThemeMode.light)).called(1);
    });

    test('still switches theme when saving fails', () async {
      when(() => settings.saveThemeMode(any()))
          .thenThrow(Exception('disk full'));
      final provider = ThemeProvider(settings)..setThemeMode(ThemeMode.dark);
      await pumpEventQueue();

      expect(provider.themeMode, ThemeMode.dark);
    });
  });
}
