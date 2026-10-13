import '../../core/errors/app_exception.dart';
import '../models/menu_category.dart';
import '../models/paged_result.dart';
import '../models/restaurant.dart';
import '../services/restaurant_api_service.dart';

class RestaurantRepository {
  RestaurantRepository(
    this._api, {
    DateTime Function()? now,
    this.menuMaxAge = const Duration(minutes: 5),
  }) : _now = now ?? DateTime.now;

  final RestaurantApiService _api;
  final DateTime Function() _now;

  /// How long a menu is reused before it is fetched again. Short, because
  /// dishes sell out; the server re-checks every order anyway.
  final Duration menuMaxAge;

  final Map<String, ({List<MenuCategory> menu, DateTime fetchedAt})> _menus =
      {};

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
      final cached = _lastFirstPage;
      if (_isOffline(error) && isFirstUnfilteredPage && cached != null) {
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

  /// The menu, reused for [menuMaxAge] so going back and forth between
  /// restaurants is instant. Offline, the last copy is better than an error.
  Future<List<MenuCategory>> getMenu(String restaurantId) async {
    final cached = _menus[restaurantId];
    if (cached != null && _now().difference(cached.fetchedAt) < menuMaxAge) {
      return cached.menu;
    }

    try {
      final menu = await _api.fetchMenu(restaurantId);
      _menus[restaurantId] = (menu: menu, fetchedAt: _now());
      return menu;
    } on AppException catch (error) {
      if (_isOffline(error) && cached != null) return cached.menu;
      rethrow;
    }
  }

  static bool _isOffline(AppException error) =>
      error is NetworkException || error is RequestTimeoutException;
}
