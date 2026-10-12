import 'package:flutter/foundation.dart';

import 'address.dart';
import 'order_status.dart';
import 'payment_method.dart';

/// An order as the API returns it. All prices were set by the server.
@immutable
class Order {
  const Order({
    required this.id,
    required this.userId,
    required this.restaurantId,
    required this.restaurantName,
    required this.items,
    required this.subtotalPesewas,
    required this.deliveryFeePesewas,
    required this.totalPesewas,
    required this.deliveryAddress,
    required this.paymentMethod,
    required this.status,
    required this.statusHistory,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as String,
      userId: json['userId'] as String,
      restaurantId: json['restaurantId'] as String,
      restaurantName: json['restaurantName'] as String,
      items: (json['items'] as List<dynamic>)
          .map((item) => OrderItem.fromJson(item as Map<String, dynamic>))
          .toList(growable: false),
      subtotalPesewas: json['subtotalPesewas'] as int,
      deliveryFeePesewas: json['deliveryFeePesewas'] as int,
      totalPesewas: json['totalPesewas'] as int,
      deliveryAddress: Address.fromJson(
        json['deliveryAddress'] as Map<String, dynamic>,
      ),
      paymentMethod: PaymentMethod.fromApi(json['paymentMethod'] as String),
      status: OrderStatus.fromApi(json['status'] as String),
      statusHistory: (json['statusHistory'] as List<dynamic>)
          .map((entry) => StatusChange.fromJson(entry as Map<String, dynamic>))
          .toList(growable: false),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  final String id;
  final String userId;
  final String restaurantId;
  final String restaurantName;
  final List<OrderItem> items;
  final int subtotalPesewas;
  final int deliveryFeePesewas;
  final int totalPesewas;
  final Address deliveryAddress;
  final PaymentMethod paymentMethod;
  final OrderStatus status;
  final List<StatusChange> statusHistory;
  final DateTime createdAt;
  final DateTime updatedAt;

  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'restaurantId': restaurantId,
    'restaurantName': restaurantName,
    'items': items.map((item) => item.toJson()).toList(),
    'subtotalPesewas': subtotalPesewas,
    'deliveryFeePesewas': deliveryFeePesewas,
    'totalPesewas': totalPesewas,
    'deliveryAddress': deliveryAddress.toJson(),
    'paymentMethod': paymentMethod.apiValue,
    'status': status.apiValue,
    'statusHistory': statusHistory.map((entry) => entry.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  Order copyWith({
    String? id,
    String? userId,
    String? restaurantId,
    String? restaurantName,
    List<OrderItem>? items,
    int? subtotalPesewas,
    int? deliveryFeePesewas,
    int? totalPesewas,
    Address? deliveryAddress,
    PaymentMethod? paymentMethod,
    OrderStatus? status,
    List<StatusChange>? statusHistory,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Order(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      restaurantId: restaurantId ?? this.restaurantId,
      restaurantName: restaurantName ?? this.restaurantName,
      items: items ?? this.items,
      subtotalPesewas: subtotalPesewas ?? this.subtotalPesewas,
      deliveryFeePesewas: deliveryFeePesewas ?? this.deliveryFeePesewas,
      totalPesewas: totalPesewas ?? this.totalPesewas,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      status: status ?? this.status,
      statusHistory: statusHistory ?? this.statusHistory,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Order &&
      other.id == id &&
      other.userId == userId &&
      other.restaurantId == restaurantId &&
      other.restaurantName == restaurantName &&
      listEquals(other.items, items) &&
      other.subtotalPesewas == subtotalPesewas &&
      other.deliveryFeePesewas == deliveryFeePesewas &&
      other.totalPesewas == totalPesewas &&
      other.deliveryAddress == deliveryAddress &&
      other.paymentMethod == paymentMethod &&
      other.status == status &&
      listEquals(other.statusHistory, statusHistory) &&
      other.createdAt == createdAt &&
      other.updatedAt == updatedAt;

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    restaurantId,
    restaurantName,
    Object.hashAll(items),
    subtotalPesewas,
    deliveryFeePesewas,
    totalPesewas,
    deliveryAddress,
    paymentMethod,
    status,
    Object.hashAll(statusHistory),
    createdAt,
    updatedAt,
  );
}

/// One priced line of an order.
@immutable
class OrderItem {
  const OrderItem({
    required this.menuItemId,
    required this.name,
    required this.unitPricePesewas,
    required this.quantity,
    this.notes = '',
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      menuItemId: json['menuItemId'] as String,
      name: json['name'] as String,
      unitPricePesewas: json['unitPricePesewas'] as int,
      quantity: json['quantity'] as int,
      notes: json['notes'] as String? ?? '',
    );
  }

  final String menuItemId;
  final String name;
  final int unitPricePesewas;
  final int quantity;
  final String notes;

  int get lineTotalPesewas => unitPricePesewas * quantity;

  Map<String, dynamic> toJson() => {
    'menuItemId': menuItemId,
    'name': name,
    'unitPricePesewas': unitPricePesewas,
    'quantity': quantity,
    'notes': notes,
  };

  OrderItem copyWith({
    String? menuItemId,
    String? name,
    int? unitPricePesewas,
    int? quantity,
    String? notes,
  }) {
    return OrderItem(
      menuItemId: menuItemId ?? this.menuItemId,
      name: name ?? this.name,
      unitPricePesewas: unitPricePesewas ?? this.unitPricePesewas,
      quantity: quantity ?? this.quantity,
      notes: notes ?? this.notes,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is OrderItem &&
      other.menuItemId == menuItemId &&
      other.name == name &&
      other.unitPricePesewas == unitPricePesewas &&
      other.quantity == quantity &&
      other.notes == notes;

  @override
  int get hashCode =>
      Object.hash(menuItemId, name, unitPricePesewas, quantity, notes);
}

/// When an order reached a status, for the tracking timeline.
@immutable
class StatusChange {
  const StatusChange({required this.status, required this.at});

  factory StatusChange.fromJson(Map<String, dynamic> json) {
    return StatusChange(
      status: OrderStatus.fromApi(json['status'] as String),
      at: DateTime.parse(json['at'] as String),
    );
  }

  final OrderStatus status;
  final DateTime at;

  Map<String, dynamic> toJson() => {
    'status': status.apiValue,
    'at': at.toIso8601String(),
  };

  StatusChange copyWith({OrderStatus? status, DateTime? at}) {
    return StatusChange(status: status ?? this.status, at: at ?? this.at);
  }

  @override
  bool operator ==(Object other) =>
      other is StatusChange && other.status == status && other.at == at;

  @override
  int get hashCode => Object.hash(status, at);
}
