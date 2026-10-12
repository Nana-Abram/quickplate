import 'package:flutter/foundation.dart';

import 'menu_item.dart';

/// One section of a restaurant menu, e.g. "Soups" and its items.
@immutable
class MenuCategory {
  const MenuCategory({required this.name, required this.items});

  factory MenuCategory.fromJson(Map<String, dynamic> json) {
    return MenuCategory(
      name: json['name'] as String,
      items: (json['items'] as List<dynamic>)
          .map((item) => MenuItem.fromJson(item as Map<String, dynamic>))
          .toList(growable: false),
    );
  }

  final String name;
  final List<MenuItem> items;

  Map<String, dynamic> toJson() => {
    'name': name,
    'items': items.map((item) => item.toJson()).toList(),
  };

  MenuCategory copyWith({String? name, List<MenuItem>? items}) {
    return MenuCategory(name: name ?? this.name, items: items ?? this.items);
  }

  @override
  bool operator ==(Object other) =>
      other is MenuCategory &&
      other.name == name &&
      listEquals(other.items, items);

  @override
  int get hashCode => Object.hash(name, Object.hashAll(items));
}
