import 'package:flutter/foundation.dart';

/// A delivery address: a short label, a written line for the rider, and the
/// point picked on the map.
@immutable
class Address {
  const Address({
    required this.label,
    required this.line1,
    required this.latitude,
    required this.longitude,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      label: json['label'] as String,
      line1: json['line1'] as String,
      latitude: (json['lat'] as num).toDouble(),
      longitude: (json['lng'] as num).toDouble(),
    );
  }

  final String label;
  final String line1;
  final double latitude;
  final double longitude;

  Map<String, dynamic> toJson() => {
    'label': label,
    'line1': line1,
    'lat': latitude,
    'lng': longitude,
  };

  Address copyWith({
    String? label,
    String? line1,
    double? latitude,
    double? longitude,
  }) {
    return Address(
      label: label ?? this.label,
      line1: line1 ?? this.line1,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Address &&
      other.label == label &&
      other.line1 == line1 &&
      other.latitude == latitude &&
      other.longitude == longitude;

  @override
  int get hashCode => Object.hash(label, line1, latitude, longitude);
}
