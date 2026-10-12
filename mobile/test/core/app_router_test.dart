import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:quickplate/core/constants/routes.dart';
import 'package:quickplate/core/router/app_router.dart';
import 'package:quickplate/data/models/app_user.dart';
import 'package:quickplate/data/models/paged_result.dart';
import 'package:quickplate/data/models/restaurant.dart';
import 'package:quickplate/providers/auth_provider.dart';
import 'package:quickplate/providers/cart_provider.dart';
import 'package:quickplate/providers/restaurants_provider.dart';
import 'package:quickplate/screens/auth/login_screen.dart';
import 'package:quickplate/screens/home/home_screen.dart';
import 'package:quickplate/screens/splash/splash_screen.dart';

import '../helpers/mocks.dart';

void main() {
  group('authRedirect', () {
    String? redirect(AuthStatus status, String location) =>
        authRedirect(status: status, location: Uri.parse(location));

    test('holds everything on the splash while the session is unknown', () {
      expect(redirect(AuthStatus.unknown, Routes.splash), isNull);
      expect(
        redirect(AuthStatus.unknown, '/orders/abc'),
        '/splash?from=%2Forders%2Fabc',
      );
    });

    test('sends signed-out users to login but allows auth routes', () {
      expect(redirect(AuthStatus.signedOut, Routes.splash), Routes.login);
      expect(redirect(AuthStatus.signedOut, Routes.home), Routes.login);
      expect(redirect(AuthStatus.signedOut, Routes.login), isNull);
      expect(redirect(AuthStatus.signedOut, Routes.register), isNull);
      expect(redirect(AuthStatus.signedOut, Routes.forgotPassword), isNull);
    });

    test('keeps signed-in users out of the auth routes', () {
      expect(redirect(AuthStatus.signedIn, Routes.login), Routes.home);
      expect(redirect(AuthStatus.signedIn, Routes.splash), Routes.home);
      expect(redirect(AuthStatus.signedIn, Routes.home), isNull);
      expect(redirect(AuthStatus.signedIn, '/orders/abc'), isNull);
    });

    test('resumes a deep link held on the splash after sign-in', () {
      expect(
        redirect(AuthStatus.signedIn, '/splash?from=%2Forders%2Fabc'),
        '/orders/abc',
      );
    });
  });

  testWidgets('router follows auth state: splash, login, home, login', (
    tester,
  ) async {
    final repository = MockAuthRepository();
    final authChanges = StreamController<AppUser?>();
    addTearDown(authChanges.close);
    when(() => repository.userChanges()).thenAnswer((_) => authChanges.stream);
    final authProvider = AuthProvider(repository);
    final router = createRouter(authProvider);
    addTearDown(router.dispose);

    final restaurants = MockRestaurantRepository();
    when(
      () => restaurants.getRestaurants(
        query: any(named: 'query'),
        category: any(named: 'category'),
        limit: any(named: 'limit'),
        cursor: any(named: 'cursor'),
      ),
    ).thenAnswer((_) async => const PagedResult<Restaurant>(items: []));

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: authProvider),
          ChangeNotifierProvider(create: (_) => CartProvider()),
          ChangeNotifierProvider(
            create: (_) => RestaurantsProvider(restaurants),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    expect(find.byType(SplashScreen), findsOneWidget);

    authChanges.add(null);
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);

    authChanges.add(const AppUser(uid: 'u1', email: 'ama@example.com'));
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);

    authChanges.add(null);
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
  });
}
