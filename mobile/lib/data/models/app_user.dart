import 'package:flutter/foundation.dart';

/// The signed-in user, independent of Firebase's `User` type.
@immutable
class AppUser {
  const AppUser({required this.uid, required this.email, this.displayName});

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      uid: json['uid'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String?,
    );
  }

  final String uid;
  final String email;
  final String? displayName;

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'email': email,
    'displayName': displayName,
  };

  AppUser copyWith({String? uid, String? email, String? displayName}) {
    return AppUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AppUser &&
      other.uid == uid &&
      other.email == email &&
      other.displayName == displayName;

  @override
  int get hashCode => Object.hash(uid, email, displayName);
}
