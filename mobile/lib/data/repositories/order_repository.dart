import '../models/address.dart';
import '../models/cart_item.dart';
import '../models/order.dart';
import '../models/payment_method.dart';
import '../services/order_api_service.dart';

class OrderRepository {
  OrderRepository(this._api);

  final OrderApiService _api;

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
}
