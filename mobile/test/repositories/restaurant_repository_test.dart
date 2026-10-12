import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quickplate/core/errors/app_exception.dart';
import 'package:quickplate/data/models/paged_result.dart';
import 'package:quickplate/data/models/restaurant.dart';
import 'package:quickplate/data/repositories/restaurant_repository.dart';

import '../helpers/fixtures.dart';
import '../helpers/mocks.dart';

void main() {
  late MockRestaurantApiService api;
  late RestaurantRepository repository;

  setUp(() {
    api = MockRestaurantApiService();
    repository = RestaurantRepository(api);
  });

  When<Future<PagedResult<Restaurant>>> whenFetch() => when(
    () => api.fetchRestaurants(
      query: any(named: 'query'),
      category: any(named: 'category'),
      limit: any(named: 'limit'),
      cursor: any(named: 'cursor'),
    ),
  );

  void stubPage(List<String> ids, {String? next}) => whenFetch().thenAnswer(
    (_) async => PagedResult(
      items: [for (final id in ids) restaurant(id: id)],
      nextCursor: next,
    ),
  );

  void stubError(AppException error) => whenFetch().thenThrow(error);

  test('offline, the last first page comes back marked as cached', () async {
    stubPage(['a'], next: 'a');
    await repository.getRestaurants(limit: 10);

    stubError(const NetworkException());
    final page = await repository.getRestaurants(limit: 10);

    expect(page.fromCache, isTrue);
    expect(page.items.single.id, 'a');
    expect(page.hasMore, isFalse);
  });

  test('a timeout also falls back to the cache', () async {
    stubPage(['a']);
    await repository.getRestaurants();

    stubError(const RequestTimeoutException());

    expect((await repository.getRestaurants()).fromCache, isTrue);
  });

  test('searches and later pages are never served from the cache', () async {
    stubPage(['a']);
    await repository.getRestaurants();
    stubError(const NetworkException());

    expect(
      () => repository.getRestaurants(query: 'osu'),
      throwsA(isA<NetworkException>()),
    );
    expect(
      () => repository.getRestaurants(cursor: 'a'),
      throwsA(isA<NetworkException>()),
    );
  });

  test('server errors are not hidden by the cache', () async {
    stubPage(['a']);
    await repository.getRestaurants();
    stubError(const ServerException());

    expect(repository.getRestaurants, throwsA(isA<ServerException>()));
  });

  test('with nothing cached the network error comes through', () async {
    stubError(const NetworkException());

    expect(repository.getRestaurants, throwsA(isA<NetworkException>()));
  });
}
