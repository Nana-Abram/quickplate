import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickplate/core/network/auth_interceptor.dart';

import '../helpers/fake_http_adapter.dart';

void main() {
  late List<bool> tokenRequests;
  String? currentToken;

  Future<String?> getIdToken({bool forceRefresh = false}) async {
    tokenRequests.add(forceRefresh);
    if (currentToken == null) return null;
    return forceRefresh ? '$currentToken-fresh' : currentToken;
  }

  Dio dioWith(FakeHttpAdapter adapter) {
    final dio = Dio(BaseOptions(baseUrl: 'http://test/v1'))
      ..httpClientAdapter = adapter;
    dio.interceptors.add(AuthInterceptor(getIdToken: getIdToken, dio: dio));
    return dio;
  }

  setUp(() {
    tokenRequests = [];
    currentToken = 'token';
  });

  test('attaches the ID token when signed in', () async {
    final adapter = FakeHttpAdapter([(200, <String, Object>{})]);

    await dioWith(adapter).get<dynamic>('/orders');

    expect(adapter.requests.single.headers['Authorization'], 'Bearer token');
  });

  test('sends no Authorization header when signed out', () async {
    currentToken = null;
    final adapter = FakeHttpAdapter([(200, <String, Object>{})]);

    await dioWith(adapter).get<dynamic>('/restaurants');

    expect(adapter.requests.single.headers, isNot(contains('Authorization')));
  });

  test('refreshes the token and retries once on 401', () async {
    final adapter = FakeHttpAdapter([
      (401, <String, Object>{}),
      (200, {'ok': true}),
    ]);

    final response = await dioWith(adapter).get<dynamic>('/orders');

    expect(response.data, {'ok': true});
    expect(adapter.requests, hasLength(2));
    expect(
      adapter.requests.last.headers['Authorization'],
      'Bearer token-fresh',
    );
    expect(tokenRequests, contains(true));
  });

  test('gives up after one retry', () async {
    final adapter = FakeHttpAdapter([
      (401, <String, Object>{}),
      (401, <String, Object>{}),
    ]);

    await expectLater(
      dioWith(adapter).get<dynamic>('/orders'),
      throwsA(
        isA<DioException>().having(
          (e) => e.response?.statusCode,
          'status',
          401,
        ),
      ),
    );
    expect(adapter.requests, hasLength(2));
  });
}
