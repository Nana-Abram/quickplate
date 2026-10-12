import 'package:flutter_test/flutter_test.dart';
import 'package:quickplate/data/models/menu_category.dart';
import 'package:quickplate/data/models/restaurant.dart';

import '../helpers/fixtures.dart';

void main() {
  test('Restaurant round-trips through JSON as the API sends it', () {
    final json = restaurantJson();

    final restaurant = Restaurant.fromJson(json);

    expect(restaurant.name, "Adwoa's Kitchen");
    expect(restaurant.rating, 4.7);
    expect(restaurant.latitude, 6.6885);
    expect(Restaurant.fromJson(restaurant.toJson()), restaurant);
  });

  test('Restaurant accepts an integer rating', () {
    final restaurant = Restaurant.fromJson(restaurantJson(rating: 5));

    expect(restaurant.rating, 5.0);
  });

  test('MenuCategory parses its items', () {
    final category = MenuCategory.fromJson({
      'name': 'Soups',
      'items': [menuItemJson(id: 'a'), menuItemJson(id: 'b')],
    });

    expect(category.items.map((i) => i.id), ['a', 'b']);
    expect(MenuCategory.fromJson(category.toJson()), category);
  });

  test('copyWith changes only the given fields', () {
    final restaurant = Restaurant.fromJson(restaurantJson());

    final closed = restaurant.copyWith(isOpen: false);

    expect(closed.isOpen, isFalse);
    expect(closed.copyWith(isOpen: true), restaurant);
  });
}
