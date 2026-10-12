import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:quickplate/core/errors/app_exception.dart';
import 'package:quickplate/core/theme/app_theme.dart';
import 'package:quickplate/data/models/paged_result.dart';
import 'package:quickplate/data/models/restaurant.dart';
import 'package:quickplate/providers/restaurants_provider.dart';
import 'package:quickplate/screens/home/widgets/restaurant_list.dart';
import 'package:quickplate/widgets/error_view.dart';
import 'package:quickplate/widgets/restaurant_card.dart';
import 'package:quickplate/widgets/shimmer_list.dart';

import '../helpers/fixtures.dart';
import '../helpers/mocks.dart';

void main() {
  late MockRestaurantRepository repository;
  late RestaurantsProvider provider;

  void stubFetch(Future<PagedResult<Restaurant>> Function() answer) {
    when(
      () => repository.getRestaurants(
        query: any(named: 'query'),
        category: any(named: 'category'),
        limit: any(named: 'limit'),
        cursor: any(named: 'cursor'),
      ),
    ).thenAnswer((_) => answer());
  }

  Future<void> pumpList(WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(body: RestaurantList()),
        ),
      ),
    );
  }

  setUp(() {
    repository = MockRestaurantRepository();
    provider = RestaurantsProvider(repository);
  });

  testWidgets('shows a shimmer while loading', (tester) async {
    final pending = Completer<PagedResult<Restaurant>>();
    stubFetch(() => pending.future);
    await pumpList(tester);

    unawaited(provider.loadInitial());
    await tester.pump();

    expect(find.byType(ShimmerList), findsOneWidget);
    pending.complete(const PagedResult(items: []));
  });

  testWidgets('shows restaurant cards on success', (tester) async {
    stubFetch(
      () async => PagedResult(
        items: [
          restaurant(id: 'a', name: 'Alpha'),
          restaurant(id: 'b'),
        ],
      ),
    );
    await pumpList(tester);

    await provider.loadInitial();
    await tester.pump();

    expect(find.byType(RestaurantCard), findsNWidgets(2));
    expect(find.text('Alpha'), findsOneWidget);
  });

  testWidgets('shows the error with a working retry', (tester) async {
    var calls = 0;
    stubFetch(() async {
      if (calls++ == 0) throw const NetworkException();
      return PagedResult(items: [restaurant()]);
    });
    await pumpList(tester);

    await provider.loadInitial();
    await tester.pump();
    expect(find.byType(ErrorView), findsOneWidget);
    expect(find.text(const NetworkException().message), findsOneWidget);

    await tester.tap(find.text('Try again'));
    await tester.pump();
    await tester.pump();

    expect(find.byType(RestaurantCard), findsOneWidget);
  });

  testWidgets('offers to clear filters when a search finds nothing', (
    tester,
  ) async {
    stubFetch(() async => const PagedResult(items: []));
    await pumpList(tester);

    await provider.selectCategory('Pizza');
    await tester.pump();

    expect(find.text('No restaurants found'), findsOneWidget);
    expect(find.text('Clear filters'), findsOneWidget);
  });
}
