import 'package:flutter/foundation.dart';

@immutable
class Restaurant {
  const Restaurant({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.categories,
    required this.rating,
    required this.deliveryFeePesewas,
    required this.etaMinutes,
    required this.isOpen,
    required this.latitude,
    required this.longitude,
  });

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    final location = json['location'] as Map<String, dynamic>;
    return Restaurant(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
      categories: List<String>.from(json['categories'] as List<dynamic>),
      rating: (json['rating'] as num).toDouble(),
      deliveryFeePesewas: json['deliveryFeePesewas'] as int,
      etaMinutes: json['etaMinutes'] as int,
      isOpen: json['isOpen'] as bool,
      latitude: (location['lat'] as num).toDouble(),
      longitude: (location['lng'] as num).toDouble(),
    );
  }

  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final List<String> categories;
  final double rating;
  final int deliveryFeePesewas;
  final int etaMinutes;
  final bool isOpen;
  final double latitude;
  final double longitude;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'imageUrl': imageUrl,
    'categories': categories,
    'rating': rating,
    'deliveryFeePesewas': deliveryFeePesewas,
    'etaMinutes': etaMinutes,
    'isOpen': isOpen,
    'location': {'lat': latitude, 'lng': longitude},
  };

  Restaurant copyWith({
    String? id,
    String? name,
    String? description,
    String? imageUrl,
    List<String>? categories,
    double? rating,
    int? deliveryFeePesewas,
    int? etaMinutes,
    bool? isOpen,
    double? latitude,
    double? longitude,
  }) {
    return Restaurant(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      categories: categories ?? this.categories,
      rating: rating ?? this.rating,
      deliveryFeePesewas: deliveryFeePesewas ?? this.deliveryFeePesewas,
      etaMinutes: etaMinutes ?? this.etaMinutes,
      isOpen: isOpen ?? this.isOpen,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Restaurant &&
      other.id == id &&
      other.name == name &&
      other.description == description &&
      other.imageUrl == imageUrl &&
      listEquals(other.categories, categories) &&
      other.rating == rating &&
      other.deliveryFeePesewas == deliveryFeePesewas &&
      other.etaMinutes == etaMinutes &&
      other.isOpen == isOpen &&
      other.latitude == latitude &&
      other.longitude == longitude;

  @override
  int get hashCode => Object.hash(
    id,
    name,
    description,
    imageUrl,
    Object.hashAll(categories),
    rating,
    deliveryFeePesewas,
    etaMinutes,
    isOpen,
    latitude,
    longitude,
  );
}
