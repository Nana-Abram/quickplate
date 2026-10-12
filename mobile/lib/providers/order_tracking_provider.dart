import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/errors/app_exception.dart';
import '../data/models/order.dart';
import '../data/repositories/order_repository.dart';
import '../data/repositories/restaurant_repository.dart';
import 'view_state.dart';

/// One order, kept current. The first load uses REST (fast, and works even
/// if Firestore is slow to connect); after that a Firestore listener pushes
/// every status change. If the listener fails, it falls back to polling REST.
/// Created with the tracking screen and disposed with it.
class OrderTrackingProvider extends ChangeNotifier {
  OrderTrackingProvider(
    this._orders,
    this._restaurants,
    this.orderId, {
    this._fallbackInterval = const Duration(seconds: 10),
  });

  /// Used for the arrival estimate when the restaurant is not cached.
  static const int defaultEtaMinutes = 40;

  final OrderRepository _orders;
  final RestaurantRepository _restaurants;
  final String orderId;
  final Duration _fallbackInterval;

  ViewState _state = ViewState.idle;
  Order? _order;
  String? _errorMessage;
  bool _isLive = false;
  bool _isUpdating = false;
  String? _actionError;

  StreamSubscription<Order>? _subscription;
  Timer? _fallbackTimer;
  bool _disposed = false;

  ViewState get state => _state;
  Order? get order => _order;
  String? get errorMessage => _errorMessage;

  /// False while updates come from polling instead of the live listener.
  bool get isLive => _isLive;

  /// A cancel or demo-advance request is in flight.
  bool get isUpdating => _isUpdating;
  String? get actionError => _actionError;

  /// When the food should arrive, or null once the order is finished.
  DateTime? get estimatedArrival {
    final order = _order;
    if (order == null || order.status.isFinal) return null;
    final eta =
        _restaurants.cachedRestaurant(order.restaurantId)?.etaMinutes ??
        defaultEtaMinutes;
    return order.createdAt.add(Duration(minutes: eta));
  }

  Future<void> load() async {
    _stopUpdates();
    _state = ViewState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _order = await _orders.getOrder(orderId);
      _state = ViewState.success;
    } on AppException catch (error) {
      _errorMessage = error.message;
      _state = ViewState.error;
      notifyListeners();
      return;
    }
    notifyListeners();
    if (!_disposed) _listen();
  }

  Future<bool> cancel() => _runAction(() => _orders.cancelOrder(orderId));

  /// Demo only: skips the simulator's wait.
  Future<bool> advance() => _runAction(() => _orders.advanceOrder(orderId));

  void _listen() {
    _subscription = _orders
        .watchOrder(orderId)
        .listen(
          (order) {
            _order = order;
            _isLive = true;
            notifyListeners();
          },
          onError: (Object _) {
            _isLive = false;
            unawaited(_subscription?.cancel());
            _subscription = null;
            _startFallback();
            notifyListeners();
          },
        );
  }

  void _startFallback() {
    _fallbackTimer?.cancel();
    _fallbackTimer = Timer.periodic(_fallbackInterval, (_) => _poll());
  }

  Future<void> _poll() async {
    if (_order?.status.isFinal ?? false) {
      _fallbackTimer?.cancel();
      return;
    }
    try {
      _order = await _orders.getOrder(orderId);
      notifyListeners();
    } on AppException {
      // Keep showing the last known state; the next tick tries again.
    }
  }

  Future<bool> _runAction(Future<Order> Function() action) async {
    if (_isUpdating) return false;
    _isUpdating = true;
    _actionError = null;
    notifyListeners();

    try {
      _order = await action();
      return true;
    } on AppException catch (error) {
      _actionError = error.message;
      return false;
    } finally {
      _isUpdating = false;
      notifyListeners();
    }
  }

  void _stopUpdates() {
    unawaited(_subscription?.cancel());
    _subscription = null;
    _fallbackTimer?.cancel();
    _fallbackTimer = null;
    _isLive = false;
  }

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _stopUpdates();
    super.dispose();
  }
}
