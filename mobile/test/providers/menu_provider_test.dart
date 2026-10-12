import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quickplate/core/errors/app_exception.dart';
import 'package:quickplate/providers/menu_provider.dart';
import 'package:quickplate/providers/view_state.dart';

import '../helpers/fixtures.dart';
import '../helpers/mocks.dart';

void main() {
  late MockRestaurantRepository repository;
  final adwoa = restaurant(id: 'adwoa');

  setUp(() => repository = MockRestaurantRepository());

  test('uses the cached restaurant and loads the menu', () async {
    when(() => repository.cachedRestaurant('adwoa')).thenReturn(adwoa);
    when(() => repository.getMenu('adwoa')).thenAnswer(
      (_) async => [
        menuCategory('Mains', [menuItem(id: 'jollof')]),
        menuCategory('Empty', []),
      ],
    );
    final provider = MenuProvider(repository, 'adwoa');
    expect(provider.restaurant, adwoa);

    await provider.load();

    expect(provider.state, ViewState.success);
    expect(provider.categories.map((c) => c.name), ['Mains']);
    verifyNever(() => repository.getRestaurant(any()));
  });

  test('fetches the restaurant when it is not cached', () async {
    when(() => repository.cachedRestaurant('adwoa')).thenReturn(null);
    when(() => repository.getRestaurant('adwoa'))
        .thenAnswer((_) async => adwoa);
    when(() => repository.getMenu('adwoa')).thenAnswer((_) async => []);
    final provider = MenuProvider(repository, 'adwoa');

    await provider.load();

    expect(provider.restaurant, adwoa);
    expect(provider.state, ViewState.empty);
  });

  test('reports errors with a friendly message', () async {
    when(() => repository.cachedRestaurant('adwoa')).thenReturn(adwoa);
    when(() => repository.getMenu('adwoa'))
        .thenThrow(const NotFoundException());
    final provider = MenuProvider(repository, 'adwoa');

    await provider.load();

    expect(provider.state, ViewState.error);
    expect(provider.errorMessage, const NotFoundException().message);
  });

  test('does not notify after the screen is gone', () async {
    when(() => repository.cachedRestaurant('adwoa')).thenReturn(adwoa);
    when(() => repository.getMenu('adwoa')).thenAnswer((_) async => []);
    final provider = MenuProvider(repository, 'adwoa');

    final loading = provider.load();
    provider.dispose();

    await expectLater(loading, completes);
  });
}
