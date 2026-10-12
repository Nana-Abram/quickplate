import 'package:flutter_test/flutter_test.dart';
import 'package:quickplate/data/models/menu_category.dart';
import 'package:quickplate/data/models/order.dart';
import 'package:quickplate/data/models/order_status.dart';
import 'package:quickplate/data/models/payment_method.dart';
import 'package:quickplate/data/models/restaurant.dart';

import '../helpers/fixtures.dart';

void main() {
  test('Restaurant round-trips through JSON as the API sends it', () {
    final json = restaurantJson();

    final restaurant = Restaurant.fromJson(json);

    expect(restaurant.name, "Adwoa's Kitchen");
    expect(restaurant.rating, 4.7);
    expect(restaurant.latitude, 6.6885);
    expect(Restaurant.fromJson(restaurant.toJson()), restaurant);
  });

  test('Restaurant accepts an integer rating', () {
    final restaurant = Restaurant.fromJson(restaurantJson(rating: 5));

    expect(restaurant.rating, 5.0);
  });

  test('MenuCategory parses its items', () {
    final category = MenuCategory.fromJson({
      'name': 'Soups',
      'items': [menuItemJson(id: 'a'), menuItemJson(id: 'b')],
    });

    expect(category.items.map((i) => i.id), ['a', 'b']);
    expect(MenuCategory.fromJson(category.toJson()), category);
  });

  test('copyWith changes only the given fields', () {
    final restaurant = Restaurant.fromJson(restaurantJson());

    final closed = restaurant.copyWith(isOpen: false);

    expect(closed.isOpen, isFalse);
    expect(closed.copyWith(isOpen: true), restaurant);
  });

  group('Order', () {
    test('parses the API shape and round-trips', () {
      final order = Order.fromJson(
        orderJson(status: 'on_the_way', history: ['placed', 'accepted']),
      );

      expect(order.status, OrderStatus.onTheWay);
      expect(order.paymentMethod, PaymentMethod.cashOnDelivery);
      expect(order.items.single.lineTotalPesewas, 9000);
      expect(order.itemCount, 2);
      expect(order.deliveryAddress.latitude, 6.69);
      expect(order.statusHistory.map((h) => h.status), [
        OrderStatus.placed,
        OrderStatus.accepted,
      ]);
      expect(order.createdAt.isUtc, isTrue);
      expect(Order.fromJson(order.toJson()), order);
    });

    test('rejects an unknown status', () {
      expect(
        () => Order.fromJson(orderJson(status: 'teleported')),
        throwsFormatException,
      );
    });

    test('only a placed order can be cancelled', () {
      expect(OrderStatus.placed.canCancel, isTrue);
      expect(OrderStatus.accepted.canCancel, isFalse);
      expect(OrderStatus.delivered.isFinal, isTrue);
      expect(OrderStatus.cancelled.isFinal, isTrue);
    });
  });
}
