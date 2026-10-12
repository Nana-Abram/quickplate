import 'package:dio/dio.dart';

/// Returns the signed-in user's Firebase ID token, or null when signed out.
typedef IdTokenProvider = Future<String?> Function({bool forceRefresh});

/// Attaches the Firebase ID token to every request while a user is signed in.
/// Public endpoints ignore it. On a 401 the token is refreshed and the request
/// retried once, which covers tokens that expired between fetch and use.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({required this._getIdToken, required this._dio});

  final IdTokenProvider _getIdToken;
  final Dio _dio;

  static const _retriedKey = 'authRetried';
  static const _header = 'Authorization';

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // A retry already carries the freshly refreshed token from onError.
    if (options.extra[_retriedKey] == true) {
      handler.next(options);
      return;
    }
    try {
      final token = await _getIdToken();
      if (token != null) options.headers[_header] = 'Bearer $token';
    } on Exception {
      // Send the request without a token; a protected endpoint answers 401,
      // which the caller handles like any other expired session.
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;
    final shouldRetry =
        err.response?.statusCode == 401 &&
        options.headers.containsKey(_header) &&
        options.extra[_retriedKey] != true;
    if (!shouldRetry) {
      handler.next(err);
      return;
    }

    try {
      final token = await _getIdToken(forceRefresh: true);
      if (token == null) {
        handler.next(err);
        return;
      }
      options
        ..headers[_header] = 'Bearer $token'
        ..extra[_retriedKey] = true;
      handler.resolve(await _dio.fetch<dynamic>(options));
    } on DioException catch (retryError) {
      handler.next(retryError);
    } on Exception {
      handler.next(err);
    }
  }
}
