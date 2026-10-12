import 'package:quickplate/data/models/menu_category.dart';
import 'package:quickplate/data/models/menu_item.dart';
import 'package:quickplate/data/models/restaurant.dart';

Map<String, dynamic> restaurantJson({
  String id = 'adwoas-kitchen',
  String name = "Adwoa's Kitchen",
  num rating = 4.7,
  bool isOpen = true,
  int deliveryFeePesewas = 1200,
}) => {
  'id': id,
  'name': name,
  'description': 'Home-style Ashanti cooking.',
  'imageUrl': 'https://picsum.photos/seed/$id/600/400',
  'categories': ['Local'],
  'rating': rating,
  'deliveryFeePesewas': deliveryFeePesewas,
  'etaMinutes': 35,
  'isOpen': isOpen,
  'location': {'lat': 6.6885, 'lng': -1.6244},
  'createdAt': '2026-10-11T00:00:00.000Z',
};

Map<String, dynamic> menuItemJson({
  String id = 'jollof',
  String name = 'Jollof Rice',
  int pricePesewas = 4500,
  bool isAvailable = true,
}) => {
  'id': id,
  'name': name,
  'description': 'Smoky party jollof.',
  'imageUrl': 'https://picsum.photos/seed/$id/600/400',
  'category': 'Mains',
  'pricePesewas': pricePesewas,
  'isAvailable': isAvailable,
};

Restaurant restaurant({
  String id = 'adwoas-kitchen',
  String name = "Adwoa's Kitchen",
  bool isOpen = true,
  int deliveryFeePesewas = 1200,
}) => Restaurant.fromJson(
  restaurantJson(
    id: id,
    name: name,
    isOpen: isOpen,
    deliveryFeePesewas: deliveryFeePesewas,
  ),
);

MenuItem menuItem({String id = 'jollof', bool isAvailable = true}) =>
    MenuItem.fromJson(menuItemJson(id: id, isAvailable: isAvailable));

MenuCategory menuCategory(String name, List<MenuItem> items) =>
    MenuCategory(name: name, items: items);
