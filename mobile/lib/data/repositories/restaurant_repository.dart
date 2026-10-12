import '../../core/errors/app_exception.dart';
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

  // The last unfiltered first page, shown when the network is down.
  PagedResult<Restaurant>? _lastFirstPage;

  Future<PagedResult<Restaurant>> getRestaurants({
    String? query,
    String? category,
    int? limit,
    String? cursor,
  }) async {
    final isFirstUnfilteredPage =
        query == null && category == null && cursor == null;

    final PagedResult<Restaurant> page;
    try {
      page = await _api.fetchRestaurants(
        query: query,
        category: category,
        limit: limit,
        cursor: cursor,
      );
    } on AppException catch (error) {
      final offline =
          error is NetworkException || error is RequestTimeoutException;
      final cached = _lastFirstPage;
      if (offline && isFirstUnfilteredPage && cached != null) {
        // No cursor: further pages cannot be fetched offline.
        return PagedResult(items: cached.items, fromCache: true);
      }
      rethrow;
    }

    if (isFirstUnfilteredPage) _lastFirstPage = page;
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
