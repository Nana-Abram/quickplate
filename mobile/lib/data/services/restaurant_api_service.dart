import 'package:dio/dio.dart';

import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_call.dart';
import '../models/menu_category.dart';
import '../models/paged_result.dart';
import '../models/restaurant.dart';

class RestaurantApiService {
  RestaurantApiService(this._dio);

  final Dio _dio;

  Future<PagedResult<Restaurant>> fetchRestaurants({
    String? query,
    String? category,
    int? limit,
    String? cursor,
  }) {
    return guardApiCall(() async {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.restaurants,
        queryParameters: {
          'q': ?query,
          'category': ?category,
          'limit': ?limit,
          'cursor': ?cursor,
        },
      );
      final data = response.data!;
      return PagedResult(
        items: (data['items'] as List<dynamic>)
            .map((json) => Restaurant.fromJson(json as Map<String, dynamic>))
            .toList(growable: false),
        nextCursor: data['nextCursor'] as String?,
      );
    });
  }

  Future<Restaurant> fetchRestaurant(String id) {
    return guardApiCall(() async {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.restaurant(id),
      );
      return Restaurant.fromJson(response.data!);
    });
  }

  Future<List<MenuCategory>> fetchMenu(String restaurantId) {
    return guardApiCall(() async {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.menu(restaurantId),
      );
      return (response.data!['categories'] as List<dynamic>)
          .map((json) => MenuCategory.fromJson(json as Map<String, dynamic>))
          .toList(growable: false);
    });
  }
}
