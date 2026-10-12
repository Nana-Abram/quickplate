import 'package:flutter/foundation.dart';

@immutable
class MenuItem {
  const MenuItem({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.category,
    required this.pricePesewas,
    required this.isAvailable,
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
      category: json['category'] as String,
      pricePesewas: json['pricePesewas'] as int,
      isAvailable: json['isAvailable'] as bool,
    );
  }

  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final String category;
  final int pricePesewas;
  final bool isAvailable;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'imageUrl': imageUrl,
    'category': category,
    'pricePesewas': pricePesewas,
    'isAvailable': isAvailable,
  };

  MenuItem copyWith({
    String? id,
    String? name,
    String? description,
    String? imageUrl,
    String? category,
    int? pricePesewas,
    bool? isAvailable,
  }) {
    return MenuItem(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      pricePesewas: pricePesewas ?? this.pricePesewas,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is MenuItem &&
      other.id == id &&
      other.name == name &&
      other.description == description &&
      other.imageUrl == imageUrl &&
      other.category == category &&
      other.pricePesewas == pricePesewas &&
      other.isAvailable == isAvailable;

  @override
  int get hashCode => Object.hash(
    id,
    name,
    description,
    imageUrl,
    category,
    pricePesewas,
    isAvailable,
  );
}
