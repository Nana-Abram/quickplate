import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/config/app_config.dart';
import 'core/network/dio_client.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/address_book_repository.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/notification_repository.dart';
import 'data/repositories/order_repository.dart';
import 'data/repositories/restaurant_repository.dart';
import 'data/repositories/settings_repository.dart';
import 'data/services/address_book_service.dart';
import 'data/services/auth_service.dart';
import 'data/services/device_api_service.dart';
import 'data/services/location_service.dart';
import 'data/services/notification_service.dart';
import 'data/services/order_api_service.dart';
import 'data/services/order_stream_service.dart';
import 'data/services/restaurant_api_service.dart';
import 'providers/address_book_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/orders_provider.dart';
import 'providers/restaurants_provider.dart';
import 'providers/theme_provider.dart';
import 'widgets/push_message_handler.dart';

/// Creates the app's object graph once: infrastructure first, then the
/// providers that depend on it.
class QuickPlateApp extends StatelessWidget {
  const QuickPlateApp({
    super.key,
    required this.config,
    required this.settings,
    this.initialThemeMode = ThemeMode.system,
  });

  final AppConfig config;
  final SettingsRepository settings;
  final ThemeMode initialThemeMode;

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
        Provider<RestaurantApiService>(
          create: (c) => RestaurantApiService(c.read()),
        ),
        Provider<OrderApiService>(create: (c) => OrderApiService(c.read())),
        Provider<OrderStreamService>(create: (_) => OrderStreamService()),
        Provider<LocationService>(create: (_) => LocationService()),
        Provider<NotificationService>(create: (_) => NotificationService()),
        Provider<AddressBookService>(create: (_) => AddressBookService()),
        Provider<DeviceApiService>(create: (c) => DeviceApiService(c.read())),
        Provider<AuthRepository>(create: (c) => AuthRepository(c.read())),
        Provider<OrderRepository>(
          create: (c) => OrderRepository(c.read(), c.read()),
        ),
        Provider<AddressBookRepository>(
          create: (c) => AddressBookRepository(c.read()),
        ),
        Provider<NotificationRepository>(
          create: (c) => NotificationRepository(c.read(), c.read()),
        ),
        Provider<RestaurantRepository>(
          create: (c) => RestaurantRepository(c.read()),
        ),

        // State
        ChangeNotifierProvider(
          create: (_) => ThemeProvider(settings, initialMode: initialThemeMode),
        ),
        ChangeNotifierProvider(create: (c) => AuthProvider(c.read())),
        ChangeNotifierProxyProvider<AuthProvider, CartProvider>(
          create: (_) => CartProvider(),
          update: (_, auth, previous) => previous!..onAuthChanged(auth.user),
        ),
        ChangeNotifierProvider(create: (c) => RestaurantsProvider(c.read())),
        ChangeNotifierProxyProvider<AuthProvider, OrdersProvider>(
          create: (c) => OrdersProvider(c.read()),
          update: (_, auth, previous) => previous!..onAuthChanged(auth.user),
        ),
        ChangeNotifierProxyProvider<AuthProvider, AddressBookProvider>(
          create: (c) => AddressBookProvider(c.read()),
          update: (_, auth, previous) => previous!..onAuthChanged(auth.user),
        ),
        ChangeNotifierProxyProvider<AuthProvider, NotificationProvider>(
          create: (c) => NotificationProvider(c.read()),
          update: (_, auth, previous) => previous!..onAuthChanged(auth.user),
        ),
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
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();

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

    return PushMessageHandler(
      router: _router,
      messengerKey: _messengerKey,
      child: MaterialApp.router(
        title: 'QuickPlate',
        debugShowCheckedModeBanner: false,
        scaffoldMessengerKey: _messengerKey,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: themeMode,
        routerConfig: _router,
      ),
    );
  }
}
