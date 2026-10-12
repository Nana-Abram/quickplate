import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'app.dart';
import 'core/config/app_config.dart';
import 'data/repositories/settings_repository.dart';
import 'data/services/preferences_service.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load();
  final config = AppConfig.fromEnv(dotenv.env);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Read before the first frame so the app opens in the saved theme.
  final settings = SettingsRepository(PreferencesService());
  final themeMode = await settings.loadThemeMode();

  runApp(
    QuickPlateApp(
      config: config,
      settings: settings,
      initialThemeMode: themeMode,
    ),
  );
}
