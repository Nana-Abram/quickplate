import 'package:flutter/material.dart';

import 'screens/splash/splash_screen.dart';

class QuickPlateApp extends StatelessWidget {
  const QuickPlateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QuickPlate',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
      ),
      home: const SplashScreen(),
    );
  }
}
