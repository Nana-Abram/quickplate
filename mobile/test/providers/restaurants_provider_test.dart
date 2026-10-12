import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quickplate/core/errors/app_exception.dart';
import 'package:quickplate/data/models/paged_result.dart';
import 'package:quickplate/data/models/restaurant.dart';
import 'package:quickplate/providers/restaurants_provider.dart';
import 'package:quickplate/providers/view_state.dart';

import '../helpers/fixtures.dart';
import '../helpers/mocks.dart';

void main() {
  late MockRestaurantRepository repository;

  PagedResult<Restaurant> page(List<String> ids, {String? next}) => PagedResult(
    items: [for (final id in ids) restaurant(id: id)],
    nextCursor: next,
  );

  void stubFetch(
    Future<PagedResult<Restaurant>> Function(Invocation call) answer,
  ) {
    when(
      () => repository.getRestaurants(
        query: any(named: 'query'),
        category: any(named: 'category'),
        limit: any(named: 'limit'),
        cursor: any(named: 'cursor'),
      ),
    ).thenAnswer(answer);
  }

  List<String> ids(RestaurantsProvider provider) =>
      provider.restaurants.map((r) => r.id).toList();

  setUp(() => repository = MockRestaurantRepository());

  group('loading the first page', () {
    test('goes loading then success', () async {
      stubFetch((_) async => page(['a', 'b']));
      final provider = RestaurantsProvider(repository);
      final states = <ViewState>[];
      provider.addListener(() => states.add(provider.state));

      await provider.loadInitial();

      expect(states, [ViewState.loading, ViewState.success]);
      expect(ids(provider), ['a', 'b']);
    });

    test('is empty when there are no restaurants', () async {
      stubFetch((_) async => page([]));
      final provider = RestaurantsProvider(repository);

      await provider.loadInitial();

      expect(provider.state, ViewState.empty);
    });

    test('exposes a friendly error and recovers on retry', () async {
      var calls = 0;
      stubFetch((_) async {
        if (calls++ == 0) throw const NetworkException();
        return page(['a']);
      });
      final provider = RestaurantsProvider(repository);

      await provider.loadInitial();
      expect(provider.state, ViewState.error);
      expect(provider.errorMessage, const NetworkException().message);

      await provider.retry();
      expect(provider.state, ViewState.success);
      expect(provider.errorMessage, isNull);
    });

    test('loadInitial only loads once', () async {
      stubFetch((_) async => page(['a']));
      final provider = RestaurantsProvider(repository);

      await provider.loadInitial();
      await provider.loadInitial();

      verify(
        () => repository.getRestaurants(
          query: any(named: 'query'),
          category: any(named: 'category'),
          limit: any(named: 'limit'),
          cursor: any(named: 'cursor'),
        ),
      ).called(1);
    });
  });

  group('pagination', () {
    test('appends the next page using the cursor', () async {
      stubFetch(
        (call) async => call.namedArguments[#cursor] == null
            ? page(['a', 'b'], next: 'b')
            : page(['c']),
      );
      final provider = RestaurantsProvider(repository);
      await provider.loadInitial();
      expect(provider.hasMore, isTrue);

      await provider.loadMore();

      expect(ids(provider), ['a', 'b', 'c']);
      expect(provider.hasMore, isFalse);
      verify(
        () => repository.getRestaurants(
          query: any(named: 'query'),
          category: any(named: 'category'),
          limit: RestaurantsProvider.pageSize,
          cursor: 'b',
        ),
      ).called(1);
    });

    test('does nothing on the last page', () async {
      stubFetch((_) async => page(['a']));
      final provider = RestaurantsProvider(repository);
      await provider.loadInitial();

      await provider.loadMore();

      expect(ids(provider), ['a']);
    });

    test(
      'keeps the list and reports an error when the next page fails',
      () async {
        stubFetch((call) async {
          if (call.namedArguments[#cursor] != null) {
            throw const ServerException();
          }
          return page(['a'], next: 'a');
        });
        final provider = RestaurantsProvider(repository);
        await provider.loadInitial();

        await provider.loadMore();

        expect(provider.state, ViewState.success);
        expect(ids(provider), ['a']);
        expect(provider.loadMoreError, const ServerException().message);
        expect(provider.isLoadingMore, isFalse);
      },
    );

    test('ignores a second loadMore while one is running', () async {
      final nextPage = Completer<PagedResult<Restaurant>>();
      stubFetch(
        (call) => call.namedArguments[#cursor] == null
            ? Future.value(page(['a'], next: 'a'))
            : nextPage.future,
      );
      final provider = RestaurantsProvider(repository);
      await provider.loadInitial();

      final first = provider.loadMore();
      await provider.loadMore();
      nextPage.complete(page(['b']));
      await first;

      expect(ids(provider), ['a', 'b']);
    });
  });

  group('filters', () {
    test('category filter reloads from the first page', () async {
      stubFetch(
        (call) async => call.namedArguments[#category] == 'Pizza'
            ? page(['pizza'])
            : page(['a', 'b']),
      );
      final provider = RestaurantsProvider(repository);
      await provider.loadInitial();

      await provider.selectCategory('Pizza');

      expect(provider.category, 'Pizza');
      expect(ids(provider), ['pizza']);
      expect(provider.hasFilters, isTrue);
    });

    // testWidgets runs on fake time, so the 400 ms debounce can be stepped.
    testWidgets('search waits 400 ms after the last keystroke', (tester) async {
      final queries = <Object?>[];
      stubFetch((call) async {
        queries.add(call.namedArguments[#query]);
        return page(['a']);
      });
      final provider = RestaurantsProvider(repository)..search('p');
      await tester.pump(const Duration(milliseconds: 200));
      provider.search('pi');
      await tester.pump(const Duration(milliseconds: 200));
      provider.search('piz');
      await tester.pump(const Duration(milliseconds: 399));
      expect(queries, isEmpty);

      await tester.pump(const Duration(milliseconds: 1));

      expect(queries, ['piz']);
      expect(provider.state, ViewState.success);
    });

    test('a slow older response never replaces newer results', () async {
      final slow = Completer<PagedResult<Restaurant>>();
      stubFetch(
        (call) => call.namedArguments[#category] == 'Pizza'
            ? Future.value(page(['pizza']))
            : slow.future,
      );
      final provider = RestaurantsProvider(repository);

      final initial = provider.loadInitial();
      await provider.selectCategory('Pizza');
      slow.complete(page(['stale']));
      await initial;

      expect(ids(provider), ['pizza']);
    });

    test('clearFilters resets query and category', () async {
      stubFetch((_) async => page(['a']));
      final provider = RestaurantsProvider(repository);
      await provider.selectCategory('Pizza');

      await provider.clearFilters();

      expect(provider.category, isNull);
      expect(provider.query, isEmpty);
      expect(provider.hasFilters, isFalse);
    });
  });

  test('flags results that came from the offline cache', () async {
    when(
      () => repository.getRestaurants(
        query: any(named: 'query'),
        category: any(named: 'category'),
        limit: any(named: 'limit'),
        cursor: any(named: 'cursor'),
      ),
    ).thenAnswer(
      (_) async => PagedResult(items: [restaurant()], fromCache: true),
    );
    final provider = RestaurantsProvider(repository);

    await provider.loadInitial();

    expect(provider.state, ViewState.success);
    expect(provider.isShowingCached, isTrue);
    expect(provider.hasMore, isFalse);
  });
}
