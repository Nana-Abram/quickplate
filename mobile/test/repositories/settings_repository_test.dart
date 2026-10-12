import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quickplate/data/repositories/settings_repository.dart';
import 'package:quickplate/data/services/preferences_service.dart';

class MockPreferencesService extends Mock implements PreferencesService {}

void main() {
  late MockPreferencesService preferences;
  late SettingsRepository settings;

  setUp(() {
    preferences = MockPreferencesService();
    settings = SettingsRepository(preferences);
  });

  test('round-trips the theme mode by name', () async {
    when(() => preferences.setString(any(), any())).thenAnswer((_) async {});
    when(() => preferences.getString('themeMode'))
        .thenAnswer((_) async => 'dark');

    await settings.saveThemeMode(ThemeMode.dark);

    verify(() => preferences.setString('themeMode', 'dark')).called(1);
    expect(await settings.loadThemeMode(), ThemeMode.dark);
  });

  test('falls back to system for missing or unknown values', () async {
    when(() => preferences.getString('themeMode'))
        .thenAnswer((_) async => null);
    expect(await settings.loadThemeMode(), ThemeMode.system);

    when(() => preferences.getString('themeMode'))
        .thenAnswer((_) async => 'sepia');
    expect(await settings.loadThemeMode(), ThemeMode.system);
  });

  test('falls back to system when storage fails', () async {
    when(() => preferences.getString(any())).thenThrow(Exception('corrupt'));

    expect(await settings.loadThemeMode(), ThemeMode.system);
  });
}
