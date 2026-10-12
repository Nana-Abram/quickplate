import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart'
    show FirebaseException, FirebaseFirestore, Timestamp;
import 'package:flutter/foundation.dart';

import '../../core/constants/firestore_paths.dart';
import '../../core/errors/app_exception.dart';
import '../../core/errors/error_mapper.dart';
import '../models/order.dart';

/// Live order updates straight from Firestore. Security rules only let a
/// signed-in user read their own orders; the backend does all the writing.
class OrderStreamService {
  OrderStreamService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// Emits the order now and on every change. Errors arrive as
  /// [AppException]s.
  Stream<Order> watchOrder(String orderId) {
    return _firestore
        .collection(FirestorePaths.orders)
        .doc(orderId)
        .snapshots()
        .map((snapshot) {
          final data = snapshot.data();
          if (data == null) throw const NotFoundException();
          return Order.fromJson({...firestoreToJson(data), 'id': snapshot.id});
        })
        .transform(
          StreamTransformer.fromHandlers(
            handleError: (error, stackTrace, sink) =>
                sink.addError(switch (error) {
                  AppException() => error,
                  FirebaseException() => mapFirebaseException(error),
                  _ => const UnknownException(),
                }, stackTrace),
          ),
        );
  }
}

/// Firestore returns [Timestamp]s where the REST API returns ISO strings.
/// Converting them lets one `Order.fromJson` serve both sources.
@visibleForTesting
Map<String, dynamic> firestoreToJson(Map<String, dynamic> data) {
  return data.map((key, value) => MapEntry(key, _convert(value)));
}

Object? _convert(Object? value) {
  return switch (value) {
    Timestamp() => value.toDate().toUtc().toIso8601String(),
    Map<String, dynamic>() => firestoreToJson(value),
    List<dynamic>() => value.map(_convert).toList(),
    _ => value,
  };
}
