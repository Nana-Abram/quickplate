import 'package:flutter_test/flutter_test.dart';
import 'package:quickplate/data/models/app_user.dart';
import 'package:quickplate/data/models/menu_item.dart';
import 'package:quickplate/providers/cart_provider.dart';

import '../helpers/fixtures.dart';

void main() {
  final adwoa = restaurant(id: 'adwoa', deliveryFeePesewas: 1200);
  final napoli = restaurant(id: 'napoli', name: 'Napoli Oven');
  final jollof = menuItem(id: 'jollof'); // 4500 pesewas
  final sobolo = MenuItem.fromJson(
    menuItemJson(id: 'sobolo', name: 'Sobolo', pricePesewas: 1000),
  );

  late CartProvider cart;
  late int notifications;

  setUp(() {
    cart = CartProvider();
    notifications = 0;
    cart.addListener(() => notifications++);
  });

  group('adding', () {
    test('adds a line with the menu price and remembers the restaurant', () {
      final result = cart.addItem(restaurant: adwoa, item: jollof, quantity: 2);

      expect(result, AddToCartResult.added);
      expect(cart.restaurant, adwoa);
      expect(cart.items.single.quantity, 2);
      expect(cart.items.single.unitPricePesewas, 4500);
      expect(cart.itemCount, 2);
      expect(notifications, 1);
    });

    test('merges the same dish with the same notes', () {
      cart
        ..addItem(restaurant: adwoa, item: jollof, notes: 'extra shito')
        ..addItem(restaurant: adwoa, item: jollof, notes: ' extra shito ');

      expect(cart.items, hasLength(1));
      expect(cart.items.single.quantity, 2);
      expect(cart.items.single.notes, 'extra shito');
    });

    test('keeps the same dish with different notes on separate lines', () {
      cart
        ..addItem(restaurant: adwoa, item: jollof)
        ..addItem(restaurant: adwoa, item: jollof, notes: 'no pepper');

      expect(cart.items, hasLength(2));
    });

    test('caps a line at 20', () {
      cart
        ..addItem(restaurant: adwoa, item: jollof, quantity: 15)
        ..addItem(restaurant: adwoa, item: jollof, quantity: 15);

      expect(cart.items.single.quantity, CartProvider.maxQuantity);
    });

    test('refuses a closed restaurant or an unavailable item', () {
      expect(
        cart.addItem(restaurant: adwoa.copyWith(isOpen: false), item: jollof),
        AddToCartResult.restaurantClosed,
      );
      expect(
        cart.addItem(
          restaurant: adwoa,
          item: jollof.copyWith(isAvailable: false),
        ),
        AddToCartResult.itemUnavailable,
      );
      expect(cart.isEmpty, isTrue);
      expect(notifications, 0);
    });

    test('refuses a 31st line', () {
      for (var i = 0; i < CartProvider.maxLines; i++) {
        cart.addItem(
          restaurant: adwoa,
          item: jollof.copyWith(id: 'item$i'),
        );
      }

      expect(
        cart.addItem(restaurant: adwoa, item: sobolo),
        AddToCartResult.cartFull,
      );
      expect(cart.items, hasLength(CartProvider.maxLines));
    });
  });

  group('switching restaurant', () {
    test('asks first and leaves the cart untouched', () {
      cart.addItem(restaurant: adwoa, item: jollof);

      final result = cart.addItem(restaurant: napoli, item: sobolo);

      expect(result, AddToCartResult.differentRestaurant);
      expect(cart.restaurant, adwoa);
      expect(cart.items.single.menuItemId, 'jollof');
    });

    test('replaces the cart once the user agrees', () {
      cart.addItem(restaurant: adwoa, item: jollof, quantity: 3);

      final result = cart.addItem(
        restaurant: napoli,
        item: sobolo,
        replaceCart: true,
      );

      expect(result, AddToCartResult.added);
      expect(cart.restaurant, napoli);
      expect(cart.items.single.menuItemId, 'sobolo');
      expect(cart.itemCount, 1);
    });

    test('needs no confirmation once the cart is empty', () {
      cart
        ..addItem(restaurant: adwoa, item: jollof)
        ..clear();

      expect(
        cart.addItem(restaurant: napoli, item: sobolo),
        AddToCartResult.added,
      );
    });
  });

  group('editing', () {
    test('increments, decrements and removes at zero', () {
      cart.addItem(restaurant: adwoa, item: jollof);
      final key = cart.items.single.key;

      cart.increment(key);
      expect(cart.items.single.quantity, 2);

      cart
        ..decrement(key)
        ..decrement(key);
      expect(cart.isEmpty, isTrue);
      expect(cart.restaurant, isNull);
    });

    test('setQuantity clamps to 20 and ignores no-op changes', () {
      cart.addItem(restaurant: adwoa, item: jollof);
      final key = cart.items.single.key;
      notifications = 0;

      cart.setQuantity(key, 99);
      expect(cart.items.single.quantity, 20);

      cart.setQuantity(key, 20);
      expect(notifications, 1);
    });

    test('removeItem drops one line', () {
      cart
        ..addItem(restaurant: adwoa, item: jollof)
        ..addItem(restaurant: adwoa, item: sobolo);

      cart.removeItem(cart.items.first.key);

      expect(cart.items.single.menuItemId, 'sobolo');
    });

    test('clear empties the cart and notifies only if needed', () {
      cart.clear();
      expect(notifications, 0);

      cart
        ..addItem(restaurant: adwoa, item: jollof)
        ..clear();

      expect(cart.isEmpty, isTrue);
      expect(cart.restaurant, isNull);
      expect(notifications, 2);
    });
  });

  group('totals', () {
    test('subtotal, delivery fee and total in pesewas', () {
      cart
        ..addItem(restaurant: adwoa, item: jollof, quantity: 2)
        ..addItem(restaurant: adwoa, item: sobolo, quantity: 3);

      expect(cart.subtotalPesewas, 2 * 4500 + 3 * 1000);
      expect(cart.deliveryFeePesewas, 1200);
      expect(cart.totalPesewas, 2 * 4500 + 3 * 1000 + 1200);
      expect(cart.itemCount, 5);
    });

    test('an empty cart costs nothing', () {
      expect(cart.subtotalPesewas, 0);
      expect(cart.deliveryFeePesewas, 0);
      expect(cart.totalPesewas, 0);
    });
  });

  group('session changes', () {
    const ama = AppUser(uid: 'ama', email: 'ama@example.com');
    const kofi = AppUser(uid: 'kofi', email: 'kofi@example.com');

    void fill() =>
        cart.addItem(restaurant: adwoa, item: jollof, notes: 'no pepper');

    test('keeps the cart while the same user stays signed in', () {
      cart.onAuthChanged(ama);
      fill();

      cart.onAuthChanged(ama);

      expect(cart.itemCount, 1);
    });

    test('empties the cart on sign-out', () {
      cart.onAuthChanged(ama);
      fill();

      cart.onAuthChanged(null);

      expect(cart.isEmpty, isTrue);
      expect(cart.restaurant, isNull);
    });

    test('never shows a cart filled by someone else', () {
      cart.onAuthChanged(ama);
      fill();

      cart.onAuthChanged(kofi);

      expect(cart.isEmpty, isTrue);
    });
  });
}
