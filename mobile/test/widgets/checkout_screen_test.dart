import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:quickplate/core/constants/routes.dart';
import 'package:quickplate/core/errors/app_exception.dart';
import 'package:quickplate/core/theme/app_theme.dart';
import 'package:quickplate/data/models/address.dart';
import 'package:quickplate/data/models/app_user.dart';
import 'package:quickplate/data/models/order.dart';
import 'package:quickplate/data/models/payment_method.dart';
import 'package:quickplate/providers/address_book_provider.dart';
import 'package:quickplate/providers/cart_provider.dart';
import 'package:quickplate/providers/orders_provider.dart';
import 'package:quickplate/screens/checkout/checkout_screen.dart';

import '../helpers/fixtures.dart';
import '../helpers/mocks.dart';

void main() {
  const pickedAddress = Address(
    label: 'Home',
    line1: '12 Prempeh II St',
    latitude: 6.69,
    longitude: -1.62,
  );

  late MockOrderRepository repository;
  late CartProvider cart;

  setUpAll(() {
    registerFallbackValue(pickedAddress);
    registerFallbackValue(PaymentMethod.cashOnDelivery);
  });

  setUp(() {
    repository = MockOrderRepository();
    cart = CartProvider()
      ..addItem(restaurant: restaurant(), item: menuItem(), quantity: 2);
  });

  void stubPlaceOrder(Future<Order> Function() answer) {
    when(
      () => repository.placeOrder(
        restaurantId: any(named: 'restaurantId'),
        items: any(named: 'items'),
        deliveryAddress: any(named: 'deliveryAddress'),
        paymentMethod: any(named: 'paymentMethod'),
      ),
    ).thenAnswer((_) => answer());
  }

  Future<void> pumpCheckout(
    WidgetTester tester, {
    AddressBookProvider? addressBook,
  }) async {
    tester.view
      ..physicalSize = const Size(1080, 2400)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final router = GoRouter(
      initialLocation: Routes.checkout,
      routes: [
        GoRoute(
          path: Routes.checkout,
          builder: (_, _) => const CheckoutScreen(),
        ),
        GoRoute(
          path: Routes.addressPicker,
          // Stands in for the map: returns an address straight away.
          builder: (context, _) => Scaffold(
            body: TextButton(
              onPressed: () => context.pop(pickedAddress),
              child: const Text('pick'),
            ),
          ),
        ),
        GoRoute(
          path: Routes.orderDetail,
          builder: (_, state) => Text('tracking ${state.pathParameters['id']}'),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: cart),
          ChangeNotifierProvider(create: (_) => OrdersProvider(repository)),
          // Signed out: no saved addresses, so the map picker opens directly.
          ChangeNotifierProvider(
            create: (_) =>
                addressBook ?? AddressBookProvider(MockAddressBookRepository()),
          ),
        ],
        child: MaterialApp.router(
          theme: AppTheme.light(),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> chooseAddress(WidgetTester tester) async {
    await tester.tap(find.text('Choose a delivery address'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('pick'));
    await tester.pumpAndSettle();
  }

  Finder placeOrderButton() => find.textContaining('Place order');

  testWidgets('needs an address before placing the order', (tester) async {
    await pumpCheckout(tester);

    await tester.tap(placeOrderButton());
    await tester.pump();

    expect(find.text('Choose a delivery address first.'), findsOneWidget);
    verifyNever(
      () => repository.placeOrder(
        restaurantId: any(named: 'restaurantId'),
        items: any(named: 'items'),
        deliveryAddress: any(named: 'deliveryAddress'),
        paymentMethod: any(named: 'paymentMethod'),
      ),
    );
  });

  testWidgets('places the order, opens tracking and empties the cart', (
    tester,
  ) async {
    stubPlaceOrder(() async => Order.fromJson(orderJson(id: 'o-42')));
    await pumpCheckout(tester);
    await chooseAddress(tester);
    expect(find.text('12 Prempeh II St'), findsOneWidget);

    await tester.tap(find.text('Card (demo)'));
    await tester.pump();
    await tester.tap(placeOrderButton());
    await tester.pumpAndSettle();

    expect(find.text('tracking o-42'), findsOneWidget);
    expect(cart.isEmpty, isTrue);
    verify(
      () => repository.placeOrder(
        restaurantId: 'adwoas-kitchen',
        items: any(named: 'items'),
        deliveryAddress: pickedAddress,
        paymentMethod: PaymentMethod.mockCard,
      ),
    ).called(1);
  });

  testWidgets('shows why the order was refused and keeps the cart', (
    tester,
  ) async {
    stubPlaceOrder(
      () => Future.error(const ConflictException('Jollof Rice is sold out.')),
    );
    await pumpCheckout(tester);
    await chooseAddress(tester);

    await tester.tap(placeOrderButton());
    await tester.pumpAndSettle();

    expect(find.text('Jollof Rice is sold out.'), findsOneWidget);
    expect(cart.isEmpty, isFalse);
  });

  testWidgets('uses the most recently saved address by default', (
    tester,
  ) async {
    const office = Address(
      label: 'Office',
      line1: 'Ridge Tower, Accra',
      latitude: 5.56,
      longitude: -0.2,
    );
    final book = MockAddressBookRepository();
    when(() => book.load('u1')).thenAnswer((_) async => [office]);
    final addressBook = AddressBookProvider(book)
      ..onAuthChanged(const AppUser(uid: 'u1', email: 'u1@example.com'));
    await tester.runAsync(pumpEventQueue);
    stubPlaceOrder(() async => Order.fromJson(orderJson(id: 'o-7')));

    await pumpCheckout(tester, addressBook: addressBook);
    expect(find.text('Office'), findsOneWidget);

    await tester.tap(placeOrderButton());
    await tester.pumpAndSettle();

    verify(
      () => repository.placeOrder(
        restaurantId: any(named: 'restaurantId'),
        items: any(named: 'items'),
        deliveryAddress: office,
        paymentMethod: any(named: 'paymentMethod'),
      ),
    ).called(1);
  });
}
