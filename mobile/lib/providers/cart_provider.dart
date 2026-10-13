import 'dart:math';

import 'package:flutter/foundation.dart';

import '../data/models/app_user.dart';
import '../data/models/cart_item.dart';
import '../data/models/menu_item.dart';
import '../data/models/restaurant.dart';

enum AddToCartResult {
  added,

  /// The cart holds another restaurant's items; ask before replacing them.
  differentRestaurant,
  restaurantClosed,
  itemUnavailable,

  /// The order already has the most lines the API accepts.
  cartFull,
}

/// In-memory cart for a single restaurant. Limits mirror the API: 1 to 20 of
/// each line and at most 30 lines.
class CartProvider extends ChangeNotifier {
  static const int maxQuantity = 20;
  static const int maxLines = 30;

  Restaurant? _restaurant;
  List<CartItem> _items = const [];
  String? _userId;

  Restaurant? get restaurant => _restaurant;
  List<CartItem> get items => _items;
  bool get isEmpty => _items.isEmpty;

  /// Total number of dishes, e.g. for the cart badge.
  int get itemCount => _items.fold(0, (sum, line) => sum + line.quantity);

  int get subtotalPesewas =>
      _items.fold(0, (sum, line) => sum + line.lineTotalPesewas);

  int get deliveryFeePesewas =>
      isEmpty ? 0 : (_restaurant?.deliveryFeePesewas ?? 0);

  int get totalPesewas => subtotalPesewas + deliveryFeePesewas;

  /// Adds [quantity] of [item]. A matching line (same dish, same notes) grows
  /// instead of being duplicated. Items from a different restaurant are only
  /// added with [replaceCart], after the user has agreed to lose the cart.
  AddToCartResult addItem({
    required Restaurant restaurant,
    required MenuItem item,
    int quantity = 1,
    String notes = '',
    bool replaceCart = false,
  }) {
    if (!restaurant.isOpen) return AddToCartResult.restaurantClosed;
    if (!item.isAvailable) return AddToCartResult.itemUnavailable;

    final switching = !isEmpty && _restaurant?.id != restaurant.id;
    if (switching && !replaceCart) return AddToCartResult.differentRestaurant;

    final items = switching ? <CartItem>[] : [..._items];
    final trimmedNotes = notes.trim();
    final added = quantity.clamp(1, maxQuantity);
    final index = items.indexWhere(
      (line) => line.menuItemId == item.id && line.notes == trimmedNotes,
    );

    if (index >= 0) {
      final line = items[index];
      items[index] = line.copyWith(
        quantity: min(line.quantity + added, maxQuantity),
      );
    } else {
      if (items.length >= maxLines) return AddToCartResult.cartFull;
      items.add(
        CartItem(
          menuItemId: item.id,
          name: item.name,
          unitPricePesewas: item.pricePesewas,
          quantity: added,
          notes: trimmedNotes,
          imageUrl: item.imageUrl,
        ),
      );
    }

    _restaurant = restaurant;
    _update(items);
    return AddToCartResult.added;
  }

  /// Sets a line's quantity; 0 or less removes it.
  void setQuantity(String key, int quantity) {
    if (quantity <= 0) {
      removeItem(key);
      return;
    }
    final index = _items.indexWhere((line) => line.key == key);
    if (index < 0) return;
    final clamped = min(quantity, maxQuantity);
    if (_items[index].quantity == clamped) return;

    final items = [..._items];
    items[index] = items[index].copyWith(quantity: clamped);
    _update(items);
  }

  void increment(String key) => _changeBy(key, 1);

  void decrement(String key) => _changeBy(key, -1);

  void removeItem(String key) {
    final items = _items.where((line) => line.key != key).toList();
    if (items.length == _items.length) return;
    _update(items);
  }

  /// Called by the proxy provider whenever the session changes. A cart
  /// (with its kitchen notes) belongs to whoever filled it, so it is
  /// dropped when someone else signs in or the user signs out. It runs
  /// during a build, so it must not notify.
  void onAuthChanged(AppUser? user) {
    if (user?.uid == _userId) return;
    _userId = user?.uid;
    _items = const [];
    _restaurant = null;
  }

  void clear() {
    if (isEmpty && _restaurant == null) return;
    _update(const []);
  }

  void _changeBy(String key, int delta) {
    final line = _items.where((l) => l.key == key).firstOrNull;
    if (line != null) setQuantity(key, line.quantity + delta);
  }

  void _update(List<CartItem> items) {
    _items = List.unmodifiable(items);
    if (_items.isEmpty) _restaurant = null;
    notifyListeners();
  }
}
