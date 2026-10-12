import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:quickplate/core/constants/routes.dart';
import 'package:quickplate/core/errors/app_exception.dart';
import 'package:quickplate/core/theme/app_theme.dart';
import 'package:quickplate/data/models/order.dart';
import 'package:quickplate/providers/order_tracking_provider.dart';
import 'package:quickplate/providers/orders_provider.dart';
import 'package:quickplate/screens/orders/orders_screen.dart';
import 'package:quickplate/screens/tracking/order_tracking_screen.dart';

import '../helpers/fixtures.dart';
import '../helpers/mocks.dart';

void main() {
  late MockOrderRepository orders;
  late MockRestaurantRepository restaurants;
  late StreamController<Order> live;

  setUp(() {
    orders = MockOrderRepository();
    restaurants = MockRestaurantRepository();
    live = StreamController<Order>();
    when(() => orders.watchOrder(any())).thenAnswer((_) => live.stream);
    when(() => restaurants.cachedRestaurant(any())).thenReturn(null);
  });

  // close() only completes once the stream had a listener, so do not wait.
  tearDown(() => unawaited(live.close()));

  void phoneSizedScreen(WidgetTester tester) {
    tester.view
      ..physicalSize = const Size(1080, 2400)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
  }

  Future<void> pumpTracking(WidgetTester tester) async {
    phoneSizedScreen(tester);
    final router = GoRouter(
      initialLocation: Routes.orderById('o1'),
      routes: [
        GoRoute(
          path: Routes.orderDetail,
          builder: (_, _) => ChangeNotifierProvider(
            create: (_) =>
                OrderTrackingProvider(orders, restaurants, 'o1')..load(),
            child: const OrderTrackingScreen(),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MaterialApp.router(theme: AppTheme.light(), routerConfig: router),
    );
    await tester.pump();
    await tester.pump();
  }

  group('OrderTrackingScreen', () {
    testWidgets('a placed order shows the timeline, items and cancel', (
      tester,
    ) async {
      when(() => orders.getOrder('o1'))
          .thenAnswer((_) async => Order.fromJson(orderJson(id: 'o1')));

      await pumpTracking(tester);

      expect(find.text('Waiting for the restaurant'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('2 × Jollof Rice'), 200);
      expect(find.text('2 × Jollof Rice'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Cancel order'), 200);
      expect(find.text('Cancel order'), findsOneWidget);
    });

    testWidgets('live updates move the order on and hide cancel', (
      tester,
    ) async {
      when(() => orders.getOrder('o1'))
          .thenAnswer((_) async => Order.fromJson(orderJson(id: 'o1')));
      await pumpTracking(tester);

      live.add(
        Order.fromJson(
          orderJson(id: 'o1', status: 'preparing', history: ['placed']),
        ),
      );
      // One pump delivers the stream event, the next rebuilds.
      await tester.pump();
      await tester.pump();

      expect(find.text('Preparing your food'), findsOneWidget);
      expect(find.text('Cancel order'), findsNothing);
    });

    testWidgets('cancel asks first, then cancels', (tester) async {
      when(() => orders.getOrder('o1'))
          .thenAnswer((_) async => Order.fromJson(orderJson(id: 'o1')));
      when(() => orders.cancelOrder('o1')).thenAnswer(
        (_) async => Order.fromJson(
          orderJson(
            id: 'o1',
            status: 'cancelled',
            history: ['placed', 'cancelled'],
          ),
        ),
      );
      await pumpTracking(tester);

      await tester.scrollUntilVisible(find.text('Cancel order'), 200);
      await tester.tap(find.text('Cancel order'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Cancel order'));
      await tester.pump();
      await tester.pump();

      await tester.scrollUntilVisible(find.text('Order cancelled'), -200);
      expect(find.text('Order cancelled'), findsOneWidget);
      verify(() => orders.cancelOrder('o1')).called(1);
    });

    testWidgets('shows a retry when the order cannot load', (tester) async {
      when(() => orders.getOrder('o1')).thenThrow(const NotFoundException());

      await pumpTracking(tester);

      expect(find.text(const NotFoundException().message), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
    });
  });

  group('OrdersScreen', () {
    Future<void> pumpOrders(WidgetTester tester) async {
      phoneSizedScreen(tester);
      final router = GoRouter(
        initialLocation: Routes.orders,
        routes: [
          GoRoute(path: Routes.orders, builder: (_, _) => const OrdersScreen()),
          GoRoute(
            path: Routes.orderDetail,
            builder: (_, state) => Text('detail ${state.pathParameters['id']}'),
          ),
          GoRoute(path: Routes.home, builder: (_, _) => const Text('home')),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => OrdersProvider(orders),
          child: MaterialApp.router(
            theme: AppTheme.light(),
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('lists orders with status chips and opens one', (tester) async {
      when(() => orders.getOrders()).thenAnswer(
        (_) async => [
          Order.fromJson(orderJson(id: 'a', status: 'delivered')),
          Order.fromJson(orderJson(id: 'b', status: 'cancelled')),
        ],
      );
      await pumpOrders(tester);

      expect(find.text('Delivered'), findsOneWidget);
      expect(find.text('Cancelled'), findsOneWidget);
      expect(find.text('2 items · GH₵102.00'), findsNWidgets(2));

      await tester.tap(find.text('Delivered'));
      await tester.pumpAndSettle();
      expect(find.text('detail a'), findsOneWidget);
    });

    testWidgets('shows the empty state', (tester) async {
      when(() => orders.getOrders()).thenAnswer((_) async => []);

      await pumpOrders(tester);

      expect(find.text('No orders yet'), findsOneWidget);
    });
  });
}
