import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'app.dart';
import 'core/config/app_config.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load();
  final config = AppConfig.fromEnv(dotenv.env);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(QuickPlateApp(config: config));
}
