import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;
import 'package:flutter_test/flutter_test.dart';
import 'package:quickplate/data/models/order.dart';
import 'package:quickplate/data/models/order_status.dart';
import 'package:quickplate/data/services/order_stream_service.dart';

import '../helpers/fixtures.dart';

void main() {
  test('converts Firestore timestamps so Order.fromJson can read them', () {
    final placedAt = Timestamp.fromDate(DateTime.utc(2026, 10, 12, 10));
    final acceptedAt = Timestamp.fromDate(
      DateTime.utc(2026, 10, 12, 10, 0, 20),
    );
    final firestoreData = {
      ...orderJson(status: 'accepted'),
      'createdAt': placedAt,
      'updatedAt': acceptedAt,
      'statusHistory': [
        {'status': 'placed', 'at': placedAt},
        {'status': 'accepted', 'at': acceptedAt},
      ],
    }..remove('id');

    final order = Order.fromJson({
      ...firestoreToJson(firestoreData),
      'id': 'order-1',
    });

    expect(order.status, OrderStatus.accepted);
    expect(order.createdAt, DateTime.utc(2026, 10, 12, 10));
    expect(order.statusHistory.last.at, DateTime.utc(2026, 10, 12, 10, 0, 20));
    expect(order.deliveryAddress.line1, '12 Prempeh II St, Adum');
  });
}
