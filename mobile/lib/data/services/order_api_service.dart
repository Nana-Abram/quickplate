import 'package:dio/dio.dart';

import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_call.dart';
import '../models/address.dart';
import '../models/cart_item.dart';
import '../models/order.dart';
import '../models/payment_method.dart';

class OrderApiService {
  OrderApiService(this._dio);

  final Dio _dio;

  /// Sends only ids, quantities and notes: the server prices every line.
  Future<Order> create({
    required String restaurantId,
    required List<CartItem> items,
    required Address deliveryAddress,
    required PaymentMethod paymentMethod,
  }) {
    return guardApiCall(() async {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.orders,
        data: {
          'restaurantId': restaurantId,
          'items': [
            for (final line in items)
              {
                'menuItemId': line.menuItemId,
                'quantity': line.quantity,
                'notes': line.notes,
              },
          ],
          'deliveryAddress': deliveryAddress.toJson(),
          'paymentMethod': paymentMethod.apiValue,
        },
      );
      return Order.fromJson(response.data!);
    });
  }

  /// The caller's most recent orders, newest first.
  Future<List<Order>> fetchOrders() {
    return guardApiCall(() async {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.orders,
      );
      return (response.data!['items'] as List<dynamic>)
          .map((json) => Order.fromJson(json as Map<String, dynamic>))
          .toList(growable: false);
    });
  }

  Future<Order> fetchOrder(String id) => _send('GET', ApiEndpoints.order(id));

  Future<Order> cancel(String id) =>
      _send('POST', ApiEndpoints.cancelOrder(id));

  /// Demo endpoint: moves the order one status forward.
  Future<Order> advance(String id) =>
      _send('POST', ApiEndpoints.advanceOrder(id));

  Future<Order> _send(String method, String path) {
    return guardApiCall(() async {
      final response = await _dio.request<Map<String, dynamic>>(
        path,
        options: Options(method: method),
      );
      return Order.fromJson(response.data!);
    });
  }
}
