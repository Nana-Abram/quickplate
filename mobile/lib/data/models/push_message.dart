import 'package:flutter/foundation.dart';

/// An order update push, reduced to what the app uses.
@immutable
class PushMessage {
  const PushMessage({this.title, this.body, this.orderId});

  factory PushMessage.fromJson(Map<String, dynamic> json) {
    return PushMessage(
      title: json['title'] as String?,
      body: json['body'] as String?,
      orderId: json['orderId'] as String?,
    );
  }

  final String? title;
  final String? body;

  /// Set by the backend so a tap can open `/orders/:id`.
  final String? orderId;

  Map<String, dynamic> toJson() => {
    'title': title,
    'body': body,
    'orderId': orderId,
  };

  PushMessage copyWith({String? title, String? body, String? orderId}) {
    return PushMessage(
      title: title ?? this.title,
      body: body ?? this.body,
      orderId: orderId ?? this.orderId,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is PushMessage &&
      other.title == title &&
      other.body == body &&
      other.orderId == orderId;

  @override
  int get hashCode => Object.hash(title, body, orderId);
}
