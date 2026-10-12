/// Paths relative to `API_BASE_URL` (which already ends in `/v1`).
abstract final class ApiEndpoints {
  static const String health = '/health';
  static const String restaurants = '/restaurants';
  static const String orders = '/orders';
  static const String deviceToken = '/me/device-token';

  static String restaurant(String id) => '/restaurants/$id';

  static String menu(String restaurantId) => '/restaurants/$restaurantId/menu';

  static String order(String id) => '/orders/$id';

  static String cancelOrder(String id) => '/orders/$id/cancel';

  static String advanceOrder(String id) => '/orders/$id/advance';
}
