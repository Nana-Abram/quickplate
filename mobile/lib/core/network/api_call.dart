import 'package:dio/dio.dart';

import '../errors/app_exception.dart';
import '../errors/error_mapper.dart';

/// Runs an API call and its response parsing, so services only ever throw
/// [AppException]s.
Future<T> guardApiCall<T>(Future<T> Function() call) async {
  try {
    return await call();
  } on DioException catch (error) {
    throw mapDioException(error);
  } on TypeError {
    // The response did not have the expected shape.
    throw const UnknownException();
  } on FormatException {
    // A value the app does not understand, e.g. a new order status.
    throw const UnknownException();
  }
}
