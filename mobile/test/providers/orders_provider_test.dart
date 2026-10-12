import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quickplate/core/errors/app_exception.dart';
import 'package:quickplate/data/models/address.dart';
import 'package:quickplate/data/models/app_user.dart';
import 'package:quickplate/data/models/cart_item.dart';
import 'package:quickplate/data/models/order.dart';
import 'package:quickplate/data/models/payment_method.dart';
import 'package:quickplate/providers/orders_provider.dart';
import 'package:quickplate/providers/view_state.dart';

import '../helpers/fixtures.dart';
import '../helpers/mocks.dart';

void main() {
  const address = Address(
    label: 'Home',
    line1: '12 Prempeh II St',
    latitude: 6.69,
    longitude: -1.62,
  );
  const items = [
    CartItem(
      menuItemId: 'jollof',
      name: 'Jollof Rice',
      unitPricePesewas: 4500,
      quantity: 2,
    ),
  ];
  final order = Order.fromJson(orderJson());

  late MockOrderRepository repository;

  setUpAll(() {
    registerFallbackValue(address);
    registerFallbackValue(PaymentMethod.cashOnDelivery);
  });

  setUp(() => repository = MockOrderRepository());

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

  Future<Order?> place(OrdersProvider provider) => provider.placeOrder(
    restaurantId: 'adwoas-kitchen',
    items: items,
    deliveryAddress: address,
    paymentMethod: PaymentMethod.cashOnDelivery,
  );

  test('places an order: loading then success', () async {
    stubPlaceOrder(() async => order);
    final provider = OrdersProvider(repository);
    final states = <ViewState>[];
    provider.addListener(() => states.add(provider.placeOrderState));

    final result = await place(provider);

    expect(result, order);
    expect(states, [ViewState.loading, ViewState.success]);
    verify(
      () => repository.placeOrder(
        restaurantId: 'adwoas-kitchen',
        items: items,
        deliveryAddress: address,
        paymentMethod: PaymentMethod.cashOnDelivery,
      ),
    ).called(1);
  });

  test('exposes the server message when the order is refused', () async {
    stubPlaceOrder(
      () => Future.error(const ConflictException('Sobolo is sold out.')),
    );
    final provider = OrdersProvider(repository);

    final result = await place(provider);

    expect(result, isNull);
    expect(provider.placeOrderState, ViewState.error);
    expect(provider.placeOrderError, 'Sobolo is sold out.');
  });

  test('ignores a second tap while placing', () async {
    final pending = Completer<Order>();
    stubPlaceOrder(() => pending.future);
    final provider = OrdersProvider(repository);

    final first = place(provider);
    final second = await place(provider);
    pending.complete(order);
    await first;

    expect(second, isNull);
    verify(
      () => repository.placeOrder(
        restaurantId: any(named: 'restaurantId'),
        items: any(named: 'items'),
        deliveryAddress: any(named: 'deliveryAddress'),
        paymentMethod: any(named: 'paymentMethod'),
      ),
    ).called(1);
  });

  test('a new user starts with a clean state', () async {
    stubPlaceOrder(() => Future.error(const NetworkException()));
    final provider = OrdersProvider(repository)
      ..onAuthChanged(const AppUser(uid: 'a', email: 'a@example.com'));
    await place(provider);

    provider.onAuthChanged(const AppUser(uid: 'b', email: 'b@example.com'));

    expect(provider.placeOrderError, isNull);
    expect(provider.placeOrderState, ViewState.idle);
  });
}
