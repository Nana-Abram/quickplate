import 'package:flutter/foundation.dart';

/// One line in the cart. The price is copied from the menu for display only;
/// the server prices the order again from its own data.
@immutable
class CartItem {
  const CartItem({
    required this.menuItemId,
    required this.name,
    required this.unitPricePesewas,
    required this.quantity,
    this.notes = '',
    this.imageUrl = '',
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      menuItemId: json['menuItemId'] as String,
      name: json['name'] as String,
      unitPricePesewas: json['unitPricePesewas'] as int,
      quantity: json['quantity'] as int,
      notes: json['notes'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
    );
  }

  final String menuItemId;
  final String name;
  final int unitPricePesewas;
  final int quantity;
  final String notes;
  final String imageUrl;

  int get lineTotalPesewas => unitPricePesewas * quantity;

  /// The same dish with different notes ("no onions") is a separate line.
  String get key => '$menuItemId::$notes';

  Map<String, dynamic> toJson() => {
    'menuItemId': menuItemId,
    'name': name,
    'unitPricePesewas': unitPricePesewas,
    'quantity': quantity,
    'notes': notes,
    'imageUrl': imageUrl,
  };

  CartItem copyWith({
    String? menuItemId,
    String? name,
    int? unitPricePesewas,
    int? quantity,
    String? notes,
    String? imageUrl,
  }) {
    return CartItem(
      menuItemId: menuItemId ?? this.menuItemId,
      name: name ?? this.name,
      unitPricePesewas: unitPricePesewas ?? this.unitPricePesewas,
      quantity: quantity ?? this.quantity,
      notes: notes ?? this.notes,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is CartItem &&
      other.menuItemId == menuItemId &&
      other.name == name &&
      other.unitPricePesewas == unitPricePesewas &&
      other.quantity == quantity &&
      other.notes == notes &&
      other.imageUrl == imageUrl;

  @override
  int get hashCode => Object.hash(
    menuItemId,
    name,
    unitPricePesewas,
    quantity,
    notes,
    imageUrl,
  );
}
