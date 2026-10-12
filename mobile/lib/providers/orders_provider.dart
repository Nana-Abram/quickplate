import 'package:flutter/foundation.dart';

import '../core/errors/app_exception.dart';
import '../data/models/address.dart';
import '../data/models/app_user.dart';
import '../data/models/cart_item.dart';
import '../data/models/order.dart';
import '../data/models/payment_method.dart';
import '../data/repositories/order_repository.dart';
import 'view_state.dart';

/// The signed-in user's order history, and placing new orders.
class OrdersProvider extends ChangeNotifier {
  OrdersProvider(this._repository);

  final OrderRepository _repository;

  String? _userId;
  ViewState _placeOrderState = ViewState.idle;
  String? _placeOrderError;
  ViewState _historyState = ViewState.idle;
  List<Order> _orders = const [];
  String? _historyError;

  ViewState get placeOrderState => _placeOrderState;
  bool get isPlacingOrder => _placeOrderState == ViewState.loading;
  String? get placeOrderError => _placeOrderError;

  ViewState get historyState => _historyState;

  /// Newest first.
  List<Order> get orders => _orders;
  String? get historyError => _historyError;

  /// Called by the proxy provider whenever the session changes, so one
  /// user's state never shows for another. It runs during a build, so it
  /// must not notify.
  void onAuthChanged(AppUser? user) {
    if (user?.uid == _userId) return;
    _userId = user?.uid;
    _placeOrderState = ViewState.idle;
    _placeOrderError = null;
    _historyState = ViewState.idle;
    _orders = const [];
    _historyError = null;
  }

  /// Loads the history. With [keepVisible] (pull-to-refresh) the current
  /// list stays on screen while it reloads.
  Future<void> loadOrders({bool keepVisible = false}) async {
    if (!keepVisible || _historyState != ViewState.success) {
      _historyState = ViewState.loading;
      _historyError = null;
      notifyListeners();
    }
    try {
      _orders = await _repository.getOrders();
      _historyError = null;
      _historyState = _orders.isEmpty ? ViewState.empty : ViewState.success;
    } on AppException catch (error) {
      _historyError = error.message;
      _historyState = ViewState.error;
    }
    notifyListeners();
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
      if (_historyState == ViewState.success ||
          _historyState == ViewState.empty) {
        _orders = [order, ..._orders];
        _historyState = ViewState.success;
      }
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
