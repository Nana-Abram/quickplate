import 'dart:io';

import 'package:dio/dio.dart';

import 'app_exception.dart';

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
