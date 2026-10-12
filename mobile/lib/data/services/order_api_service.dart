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
}
