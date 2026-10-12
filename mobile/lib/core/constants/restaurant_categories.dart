/// Filter chips on the home screen. They match the `categories` values the
/// backend seeds; the API has no categories endpoint.
abstract final class RestaurantCategories {
  static const List<String> all = [
    'Local',
    'Fast Food',
    'Pizza',
    'Healthy',
    'Drinks',
  ];
}
