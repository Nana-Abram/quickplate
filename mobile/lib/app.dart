import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/config/app_config.dart';
import 'core/network/dio_client.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/auth_repository.dart';
import 'data/services/auth_service.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';

/// Creates the app's object graph once: infrastructure first, then the
/// providers that depend on it.
class QuickPlateApp extends StatelessWidget {
  const QuickPlateApp({super.key, required this.config});

  final AppConfig config;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Infrastructure (plain objects)
        Provider<AppConfig>.value(value: config),
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<Dio>(
          create: (c) => buildDio(
            baseUrl: config.apiBaseUrl,
            getIdToken: c.read<AuthService>().getIdToken,
          ),
          dispose: (_, dio) => dio.close(),
        ),
        Provider<AuthRepository>(create: (c) => AuthRepository(c.read())),

        // State
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (c) => AuthProvider(c.read())),
      ],
      child: const _AppView(),
    );
  }
}

class _AppView extends StatefulWidget {
  const _AppView();

  @override
  State<_AppView> createState() => _AppViewState();
}

class _AppViewState extends State<_AppView> {
  // Created once: rebuilding the router would reset navigation.
  late final GoRouter _router = createRouter(context.read<AuthProvider>());

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = context.select<ThemeProvider, ThemeMode>(
      (p) => p.themeMode,
    );

    return MaterialApp.router(
      title: 'QuickPlate',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: _router,
    );
  }
}
