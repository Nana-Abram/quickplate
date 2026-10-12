import '../models/menu_category.dart';
import '../models/paged_result.dart';
import '../models/restaurant.dart';
import '../services/restaurant_api_service.dart';

class RestaurantRepository {
  RestaurantRepository(this._api);

  final RestaurantApiService _api;

  // Restaurants seen in any list, so the detail screen can draw its header
  // immediately while the menu loads.
  final Map<String, Restaurant> _byId = {};

  Future<PagedResult<Restaurant>> getRestaurants({
    String? query,
    String? category,
    int? limit,
    String? cursor,
  }) async {
    final page = await _api.fetchRestaurants(
      query: query,
      category: category,
      limit: limit,
      cursor: cursor,
    );
    for (final restaurant in page.items) {
      _byId[restaurant.id] = restaurant;
    }
    return page;
  }

  Restaurant? cachedRestaurant(String id) => _byId[id];

  Future<Restaurant> getRestaurant(String id) async {
    final restaurant = await _api.fetchRestaurant(id);
    _byId[id] = restaurant;
    return restaurant;
  }

  Future<List<MenuCategory>> getMenu(String restaurantId) {
    return _api.fetchMenu(restaurantId);
  }
}
