import 'package:flutter/foundation.dart';

import '../core/errors/app_exception.dart';
import '../data/models/address.dart';
import '../data/models/app_user.dart';
import '../data/models/cart_item.dart';
import '../data/models/order.dart';
import '../data/models/payment_method.dart';
import '../data/repositories/order_repository.dart';
import 'view_state.dart';

/// Placing orders (and, from Phase 7, the order history) for the signed-in
/// user.
class OrdersProvider extends ChangeNotifier {
  OrdersProvider(this._repository);

  final OrderRepository _repository;

  String? _userId;
  ViewState _placeOrderState = ViewState.idle;
  String? _placeOrderError;

  ViewState get placeOrderState => _placeOrderState;
  bool get isPlacingOrder => _placeOrderState == ViewState.loading;
  String? get placeOrderError => _placeOrderError;

  /// Called by the proxy provider whenever the session changes, so one
  /// user's state never shows for another. It runs during a build, so it
  /// must not notify.
  void onAuthChanged(AppUser? user) {
    if (user?.uid == _userId) return;
    _userId = user?.uid;
    _placeOrderState = ViewState.idle;
    _placeOrderError = null;
  }

  /// Returns the created order, or null with [placeOrderError] set.
  Future<Order?> placeOrder({
    required String restaurantId,
    required List<CartItem> items,
    required Address deliveryAddress,
    required PaymentMethod paymentMethod,
  }) async {
    if (isPlacingOrder) return null;
    _placeOrderState = ViewState.loading;
    _placeOrderError = null;
    notifyListeners();

    try {
      final order = await _repository.placeOrder(
        restaurantId: restaurantId,
        items: items,
        deliveryAddress: deliveryAddress,
        paymentMethod: paymentMethod,
      );
      _placeOrderState = ViewState.success;
      return order;
    } on AppException catch (error) {
      _placeOrderError = error.message;
      _placeOrderState = ViewState.error;
      return null;
    } finally {
      notifyListeners();
    }
  }

  void clearPlaceOrderError() {
    if (_placeOrderError == null) return;
    _placeOrderError = null;
    _placeOrderState = ViewState.idle;
    notifyListeners();
  }
}
