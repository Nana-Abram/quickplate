/// A home-screen category filter. [name] matches the `categories` values
/// the backend seeds (the API has no categories endpoint).
class RestaurantCategory {
  const RestaurantCategory(this.name, this.imageUrl);

  final String name;

  /// A dish that stands for the category. Credited in
  /// docs/PHOTO_CREDITS.md.
  final String imageUrl;
}

abstract final class RestaurantCategories {
  static const List<RestaurantCategory> all = [
    RestaurantCategory(
      'Local',
      'https://upload.wikimedia.org/wikipedia/commons/thumb/8/80/Fufu_with_groundnut_soup.jpg/960px-Fufu_with_groundnut_soup.jpg',
    ),
    RestaurantCategory(
      'Rice',
      'https://live.staticflickr.com/8211/8429570123_d52389432f_b.jpg',
    ),
    RestaurantCategory(
      'Grills',
      'https://pd.w.org/2026/02/484699ec4afd701d2.34442495-1024x910.jpeg',
    ),
    RestaurantCategory(
      'Seafood',
      'https://pd.w.org/2026/07/3096a5bde86c9be25.93330742-1024x768.jpg',
    ),
    RestaurantCategory(
      'Fast Food',
      'https://pd.w.org/2024/02/31865c7d753895f47.99510493-1024x770.jpeg',
    ),
    RestaurantCategory(
      'Pizza',
      'https://live.staticflickr.com/54/178449500_1db4e1159b_b.jpg',
    ),
    RestaurantCategory(
      'Healthy',
      'https://pd.w.org/2022/09/674632a8c97e42602.57162826-1024x768.jpg',
    ),
    RestaurantCategory(
      'Drinks',
      'https://pd.w.org/2024/02/65465bb767928dd90.18779803-636x1024.jpg',
    ),
  ];
}
