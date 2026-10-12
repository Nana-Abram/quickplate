import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quickplate/core/errors/app_exception.dart';
import 'package:quickplate/data/models/order.dart';
import 'package:quickplate/data/models/order_status.dart';
import 'package:quickplate/providers/order_tracking_provider.dart';
import 'package:quickplate/providers/view_state.dart';

import '../helpers/fixtures.dart';
import '../helpers/mocks.dart';

Order orderWith(String status, {List<String>? history}) => Order.fromJson(
  orderJson(id: 'o1', status: status, history: history ?? ['placed']),
);

void main() {
  late MockOrderRepository orders;
  late MockRestaurantRepository restaurants;
  late StreamController<Order> live;

  setUp(() {
    orders = MockOrderRepository();
    restaurants = MockRestaurantRepository();
    live = StreamController<Order>();
    when(() => orders.watchOrder('o1')).thenAnswer((_) => live.stream);
    when(() => restaurants.cachedRestaurant(any())).thenReturn(null);
  });

  // close() only completes once the stream had a listener, so do not wait.
  tearDown(() => unawaited(live.close()));

  OrderTrackingProvider tracker({Duration? fallback}) => OrderTrackingProvider(
    orders,
    restaurants,
    'o1',
    fallbackInterval: fallback ?? const Duration(seconds: 10),
  );

  test('loads over REST, then follows the live stream', () async {
    when(() => orders.getOrder('o1'))
        .thenAnswer((_) async => orderWith('placed'));
    final provider = tracker();

    await provider.load();
    expect(provider.state, ViewState.success);
    expect(provider.order?.status, OrderStatus.placed);

    live.add(orderWith('accepted'));
    await pumpEventQueue();

    expect(provider.order?.status, OrderStatus.accepted);
    expect(provider.isLive, isTrue);
  });

  test('shows an error when the first load fails, and retries', () async {
    var calls = 0;
    when(() => orders.getOrder('o1')).thenAnswer((_) async {
      if (calls++ == 0) throw const NetworkException();
      return orderWith('placed');
    });
    final provider = tracker();

    await provider.load();
    expect(provider.state, ViewState.error);
    expect(provider.errorMessage, const NetworkException().message);
    verifyNever(() => orders.watchOrder(any()));

    await provider.load();
    expect(provider.state, ViewState.success);
  });

  testWidgets('falls back to polling REST when the stream fails', (
    tester,
  ) async {
    var status = 'placed';
    when(() => orders.getOrder('o1'))
        .thenAnswer((_) async => orderWith(status));
    final provider = tracker(fallback: const Duration(seconds: 5));
    await provider.load();

    live.addError(const ForbiddenException());
    await tester.pump();
    expect(provider.isLive, isFalse);

    status = 'preparing';
    await tester.pump(const Duration(seconds: 5));

    expect(provider.order?.status, OrderStatus.preparing);
    provider.dispose();
  });

  test('cancel replaces the order with the server result', () async {
    when(() => orders.getOrder('o1'))
        .thenAnswer((_) async => orderWith('placed'));
    when(() => orders.cancelOrder('o1')).thenAnswer(
      (_) async => orderWith('cancelled', history: ['placed', 'cancelled']),
    );
    final provider = tracker();
    await provider.load();

    final ok = await provider.cancel();

    expect(ok, isTrue);
    expect(provider.order?.status, OrderStatus.cancelled);
    expect(provider.isUpdating, isFalse);
  });

  test('a refused cancel keeps the order and explains why', () async {
    when(() => orders.getOrder('o1'))
        .thenAnswer((_) async => orderWith('placed'));
    when(() => orders.cancelOrder('o1')).thenThrow(
      const ConflictException(
        'Only orders that have not been accepted yet can be cancelled.',
      ),
    );
    final provider = tracker();
    await provider.load();

    final ok = await provider.cancel();

    expect(ok, isFalse);
    expect(provider.order?.status, OrderStatus.placed);
    expect(provider.actionError, startsWith('Only orders'));
  });

  test(
    'estimates arrival from the restaurant ETA, none once delivered',
    () async {
      when(() => restaurants.cachedRestaurant('adwoas-kitchen'))
          .thenReturn(restaurant());
      when(() => orders.getOrder('o1'))
          .thenAnswer((_) async => orderWith('preparing'));
      final provider = tracker();
      await provider.load();

      expect(
        provider.estimatedArrival,
        DateTime.utc(2026, 10, 12, 10).add(const Duration(minutes: 35)),
      );

      live.add(orderWith('delivered'));
      await pumpEventQueue();
      expect(provider.estimatedArrival, isNull);
    },
  );

  test('stops listening when disposed', () async {
    when(() => orders.getOrder('o1'))
        .thenAnswer((_) async => orderWith('placed'));
    final provider = tracker();
    await provider.load();
    expect(live.hasListener, isTrue);

    provider.dispose();
    await pumpEventQueue();

    expect(live.hasListener, isFalse);
  });
}
