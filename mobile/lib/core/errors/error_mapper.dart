import 'dart:io';

import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'app_exception.dart';

/// Turns Firebase Auth error codes into messages a user can act on.
AppException mapFirebaseAuthException(FirebaseAuthException error) {
  return switch (error.code) {
    // Recent SDKs report a wrong password or unknown email as
    // invalid-credential, so both get the same deliberately vague message.
    'invalid-credential' ||
    'wrong-password' ||
    'user-not-found' ||
    'INVALID_LOGIN_CREDENTIALS' => const AuthException(
      'Incorrect email or password.',
    ),
    'invalid-email' => const AuthException('That email address is not valid.'),
    'user-disabled' => const AuthException(
      'This account has been disabled. Please contact support.',
    ),
    'email-already-in-use' => const AuthException(
      'An account already exists for that email. Try signing in instead.',
    ),
    'weak-password' => const AuthException(
      'Choose a stronger password with at least 8 characters.',
    ),
    'too-many-requests' => const AuthException(
      'Too many attempts. Please wait a few minutes and try again.',
    ),
    'operation-not-allowed' => const AuthException(
      'Email sign-in is not available right now.',
    ),
    'network-request-failed' => const NetworkException(),
    _ => const AuthException('Something went wrong. Please try again.'),
  };
}

/// The single place where Dio errors become [AppException]s.
AppException mapDioException(DioException error) {
  return switch (error.type) {
    DioExceptionType.connectionTimeout ||
    DioExceptionType.sendTimeout ||
    DioExceptionType.receiveTimeout ||
    DioExceptionType.transformTimeout => const RequestTimeoutException(),
    DioExceptionType.connectionError => const NetworkException(),
    DioExceptionType.badCertificate => const NetworkException(
      'Could not make a secure connection. Please try again.',
    ),
    DioExceptionType.badResponse => _fromResponse(error.response),
    DioExceptionType.cancel => const UnknownException(),
    DioExceptionType.unknown =>
      error.error is SocketException
          ? const NetworkException()
          : const UnknownException(),
  };
}

AppException _fromResponse(Response<dynamic>? response) {
  final status = response?.statusCode ?? 0;
  return switch (status) {
    400 => const ValidationException(),
    401 => const UnauthorizedException(),
    403 => const ForbiddenException(),
    404 => const NotFoundException(),
    // Only conflict messages are shown as-is: the API writes them for users
    // ("Sobolo is not available right now."), unlike its validation detail.
    409 => switch (_serverMessage(response?.data)) {
      final String message => ConflictException(message),
      null => const ConflictException(),
    },
    429 => const RateLimitException(),
    >= 500 => const ServerException(),
    _ => const UnknownException(),
  };
}

/// Reads `message` from the API error shape `{ "error": { "code", "message" } }`.
String? _serverMessage(Object? body) {
  if (body case {'error': {'message': final String message}}
      when message.isNotEmpty) {
    return message;
  }
  return null;
}
