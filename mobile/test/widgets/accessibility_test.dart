import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:quickplate/core/theme/app_theme.dart';
import 'package:quickplate/data/models/app_user.dart';
import 'package:quickplate/data/models/order.dart';
import 'package:quickplate/data/models/paged_result.dart';
import 'package:quickplate/data/models/restaurant.dart';
import 'package:quickplate/providers/address_book_provider.dart';
import 'package:quickplate/providers/auth_provider.dart';
import 'package:quickplate/providers/cart_provider.dart';
import 'package:quickplate/providers/restaurants_provider.dart';
import 'package:quickplate/providers/theme_provider.dart';
import 'package:quickplate/screens/auth/login_screen.dart';
import 'package:quickplate/screens/cart/cart_screen.dart';
import 'package:quickplate/screens/home/widgets/restaurant_list.dart';
import 'package:quickplate/screens/orders/widgets/order_card.dart';
import 'package:quickplate/screens/profile/profile_screen.dart';

import '../helpers/fixtures.dart';
import '../helpers/mocks.dart';

/// Every screen here must meet Android's tap target size, label its
/// controls, keep text readable, and survive double-size text.
void main() {
  late MockAuthRepository auth;
  late MockRestaurantRepository restaurants;
  late StreamController<AppUser?> userChanges;

  setUp(() {
    auth = MockAuthRepository();
    restaurants = MockRestaurantRepository();
    userChanges = StreamController<AppUser?>();
    when(() => auth.userChanges()).thenAnswer((_) => userChanges.stream);
    when(
      () => restaurants.getRestaurants(
        query: any(named: 'query'),
        category: any(named: 'category'),
        limit: any(named: 'limit'),
        cursor: any(named: 'cursor'),
      ),
    ).thenAnswer(
      (_) async => PagedResult<Restaurant>(
        // No image URLs: the cached image loader needs platform plugins
        // that widget tests do not have, and the placeholder is what shows.
        items: [
          restaurant(id: 'a').copyWith(imageUrl: ''),
          restaurant(
            id: 'b',
            isOpen: false,
            deliveryFeePesewas: 0,
          ).copyWith(imageUrl: ''),
        ],
      ),
    );
  });

  tearDown(() => unawaited(userChanges.close()));

  Future<void> pumpScreen(
    WidgetTester tester,
    Widget screen, {
    double textScale = 1,
    ThemeData? theme,
  }) async {
    final cart = CartProvider()
      ..addItem(
        restaurant: restaurant(),
        item: menuItem(),
        quantity: 2,
        notes: 'extra shito',
      );
    final restaurantsProvider = RestaurantsProvider(restaurants);
    // Signed in with no saved addresses, as on a real profile screen.
    final book = MockAddressBookRepository();
    when(() => book.load(any())).thenAnswer((_) async => []);
    final addressBook = AddressBookProvider(book)
      ..onAuthChanged(const AppUser(uid: 'u1', email: 'ama@example.com'));
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider(auth)),
          ChangeNotifierProvider.value(value: cart),
          ChangeNotifierProvider.value(value: restaurantsProvider),
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider.value(value: addressBook),
        ],
        child: MaterialApp(
          theme: theme ?? AppTheme.light(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
          home: screen,
        ),
      ),
    );
    await restaurantsProvider.loadInitial();
    await tester.pumpAndSettle();
  }

  final screens = <String, Widget>{
    'login': const LoginScreen(),
    'home list': const Scaffold(body: RestaurantList()),
    'cart': const CartScreen(),
    'profile': const ProfileScreen(),
    'order card': Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: OrderCard(
          order: Order.fromJson(orderJson(status: 'on_the_way')),
          onTap: () {},
        ),
      ),
    ),
  };

  for (final MapEntry(key: name, value: screen) in screens.entries) {
    group(name, () {
      testWidgets('meets tap target, label and contrast guidelines', (
        tester,
      ) async {
        final semantics = tester.ensureSemantics();
        await pumpScreen(tester, screen);

        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        semantics.dispose();
      });

      testWidgets('lays out at double text size', (tester) async {
        await pumpScreen(tester, screen, textScale: 2);

        expect(tester.takeException(), isNull);
      });

      testWidgets('meets contrast in dark mode', (tester) async {
        final semantics = tester.ensureSemantics();
        await pumpScreen(tester, screen, theme: AppTheme.dark());

        await expectLater(tester, meetsGuideline(textContrastGuideline));
        semantics.dispose();
      });
    });
  }
}
