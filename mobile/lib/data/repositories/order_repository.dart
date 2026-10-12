import '../models/address.dart';
import '../models/cart_item.dart';
import '../models/order.dart';
import '../models/payment_method.dart';
import '../services/order_api_service.dart';
import '../services/order_stream_service.dart';

class OrderRepository {
  OrderRepository(this._api, this._stream);

  final OrderApiService _api;
  final OrderStreamService _stream;

  Future<Order> placeOrder({
    required String restaurantId,
    required List<CartItem> items,
    required Address deliveryAddress,
    required PaymentMethod paymentMethod,
  }) {
    return _api.create(
      restaurantId: restaurantId,
      items: items,
      deliveryAddress: deliveryAddress,
      paymentMethod: paymentMethod,
    );
  }

  Future<List<Order>> getOrders() => _api.fetchOrders();

  Future<Order> getOrder(String id) => _api.fetchOrder(id);

  Stream<Order> watchOrder(String id) => _stream.watchOrder(id);

  Future<Order> cancelOrder(String id) => _api.cancel(id);

  Future<Order> advanceOrder(String id) => _api.advance(id);
}
