/// Base type for every error the data layer throws. [message] is written for
/// users and is safe to show in the UI; raw error text never reaches it.
sealed class AppException implements Exception {
  const AppException(this.message);

  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

class NetworkException extends AppException {
  const NetworkException([
    super.message = 'No internet connection. Check your network and try again.',
  ]);
}

class RequestTimeoutException extends AppException {
  const RequestTimeoutException([
    super.message =
        'The server is taking too long to respond. Please try again.',
  ]);
}

class UnauthorizedException extends AppException {
  const UnauthorizedException([
    super.message = 'Your session has expired. Please sign in again.',
  ]);
}

class ForbiddenException extends AppException {
  const ForbiddenException([super.message = 'You do not have access to this.']);
}

class NotFoundException extends AppException {
  const NotFoundException([
    super.message = 'We could not find what you were looking for.',
  ]);
}

/// The request was valid but the current state does not allow it, e.g. a
/// closed restaurant. The server writes these messages for users.
class ConflictException extends AppException {
  const ConflictException([
    super.message = 'This action is not possible right now.',
  ]);
}

class ValidationException extends AppException {
  const ValidationException([
    super.message = 'Some details are not valid. Please check and try again.',
  ]);
}

class RateLimitException extends AppException {
  const RateLimitException([
    super.message = 'Too many requests. Please wait a moment and try again.',
  ]);
}

class ServerException extends AppException {
  const ServerException([
    super.message = 'Something went wrong on our side. Please try again.',
  ]);
}

/// Sign-in, registration and password reset failures.
class AuthException extends AppException {
  const AuthException(super.message);
}

/// Location could not be read: services off, permission refused, or no fix.
class LocationException extends AppException {
  const LocationException(super.message, {this.canOpenSettings = false});

  /// True when only the system settings can grant access again.
  final bool canOpenSettings;
}

class UnknownException extends AppException {
  const UnknownException([
    super.message = 'Something went wrong. Please try again.',
  ]);
}
