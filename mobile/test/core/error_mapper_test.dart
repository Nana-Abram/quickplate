import 'dart:io';

import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickplate/core/errors/app_exception.dart';
import 'package:quickplate/core/errors/error_mapper.dart';

DioException responseError(int status, [Object? body]) {
  final options = RequestOptions(path: '/x');
  return DioException.badResponse(
    statusCode: status,
    requestOptions: options,
    response: Response<dynamic>(
      requestOptions: options,
      statusCode: status,
      data: body,
    ),
  );
}

void main() {
  group('mapDioException', () {
    test('maps timeouts and connection failures', () {
      final options = RequestOptions(path: '/x');

      expect(
        mapDioException(
          DioException.connectionTimeout(
            timeout: const Duration(seconds: 1),
            requestOptions: options,
          ),
        ),
        isA<RequestTimeoutException>(),
      );
      expect(
        mapDioException(
          DioException.connectionError(
            requestOptions: options,
            reason: 'refused',
          ),
        ),
        isA<NetworkException>(),
      );
      expect(
        mapDioException(
          DioException(
            requestOptions: options,
            error: const SocketException('down'),
          ),
        ),
        isA<NetworkException>(),
      );
    });

    test('maps HTTP status codes', () {
      expect(mapDioException(responseError(400)), isA<ValidationException>());
      expect(mapDioException(responseError(401)), isA<UnauthorizedException>());
      expect(mapDioException(responseError(403)), isA<ForbiddenException>());
      expect(mapDioException(responseError(404)), isA<NotFoundException>());
      expect(mapDioException(responseError(429)), isA<RateLimitException>());
      expect(mapDioException(responseError(503)), isA<ServerException>());
    });

    test('uses the server message for conflicts', () {
      final error = mapDioException(
        responseError(409, {
          'error': {
            'code': 'conflict',
            'message': 'Sobolo is not available right now.',
          },
        }),
      );

      expect(error, isA<ConflictException>());
      expect(error.message, 'Sobolo is not available right now.');
    });

    test('never exposes server detail for validation errors', () {
      final error = mapDioException(
        responseError(400, {
          'error': {
            'code': 'validation_error',
            'message': 'items.0.quantity: Too big',
          },
        }),
      );

      expect(error.message, isNot(contains('items.0')));
    });

    test('falls back to a generic conflict message for odd bodies', () {
      expect(
        mapDioException(responseError(409, 'not json')).message,
        const ConflictException().message,
      );
    });
  });

  group('mapFirebaseAuthException', () {
    AppException map(String code) =>
        mapFirebaseAuthException(FirebaseAuthException(code: code));

    test('gives one vague message for wrong password or unknown email', () {
      final messages = {
        map('invalid-credential').message,
        map('wrong-password').message,
        map('user-not-found').message,
      };

      expect(messages, {'Incorrect email or password.'});
    });

    test('maps account and network problems', () {
      expect(map('email-already-in-use').message, contains('already exists'));
      expect(map('weak-password').message, contains('stronger'));
      expect(map('too-many-requests').message, contains('Too many attempts'));
      expect(map('network-request-failed'), isA<NetworkException>());
    });

    test('never shows an unknown Firebase code to the user', () {
      final error = map('internal-error');

      expect(error, isA<AuthException>());
      expect(error.message, isNot(contains('internal-error')));
    });
  });

  group('mapFirebaseException', () {
    AppException map(String code) => mapFirebaseException(
      FirebaseException(plugin: 'cloud_firestore', code: code),
    );

    test('maps Firestore error codes', () {
      expect(map('permission-denied'), isA<ForbiddenException>());
      expect(map('unavailable'), isA<NetworkException>());
      expect(map('not-found'), isA<NotFoundException>());
      expect(map('something-new'), isA<UnknownException>());
    });
  });
}
