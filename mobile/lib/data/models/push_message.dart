import 'package:flutter/foundation.dart';

/// An order update push, reduced to what the app uses.
@immutable
class PushMessage {
  const PushMessage({this.messageId, this.title, this.body, this.orderId});

  factory PushMessage.fromJson(Map<String, dynamic> json) {
    return PushMessage(
      messageId: json['messageId'] as String?,
      title: json['title'] as String?,
      body: json['body'] as String?,
      orderId: json['orderId'] as String?,
    );
  }

  /// FCM's id for this delivery, used to handle each tap once.
  final String? messageId;
  final String? title;
  final String? body;

  /// Set by the backend so a tap can open `/orders/:id`.
  final String? orderId;

  Map<String, dynamic> toJson() => {
    'messageId': messageId,
    'title': title,
    'body': body,
    'orderId': orderId,
  };

  PushMessage copyWith({
    String? messageId,
    String? title,
    String? body,
    String? orderId,
  }) {
    return PushMessage(
      messageId: messageId ?? this.messageId,
      title: title ?? this.title,
      body: body ?? this.body,
      orderId: orderId ?? this.orderId,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is PushMessage &&
      other.messageId == messageId &&
      other.title == title &&
      other.body == body &&
      other.orderId == orderId;

  @override
  int get hashCode => Object.hash(messageId, title, body, orderId);
}
