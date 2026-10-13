import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'auth_interceptor.dart';

Dio buildDio({required String baseUrl, required IdTokenProvider getIdToken}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      // Generous, because the free API host sleeps when idle and takes up to
      // a minute to answer the first request after that. The shimmer shows
      // meanwhile, which beats an error the user has to retry.
      receiveTimeout: const Duration(seconds: 60),
      contentType: Headers.jsonContentType,
      responseType: ResponseType.json,
    ),
  );

  dio.interceptors.add(AuthInterceptor(getIdToken: getIdToken, dio: dio));

  if (kDebugMode) {
    dio.interceptors.add(
      LogInterceptor(
        // Headers carry the ID token, so they are never logged.
        requestHeader: false,
        responseHeader: false,
        requestBody: true,
        logPrint: (line) => debugPrint(line.toString()),
      ),
    );
  }

  return dio;
}
