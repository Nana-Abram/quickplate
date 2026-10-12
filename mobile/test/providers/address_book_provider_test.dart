import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quickplate/core/errors/app_exception.dart';
import 'package:quickplate/data/models/address.dart';
import 'package:quickplate/data/models/app_user.dart';
import 'package:quickplate/providers/address_book_provider.dart';
import 'package:quickplate/providers/view_state.dart';

import '../helpers/mocks.dart';

Address address(String label, String line1, {double lat = 6.69}) =>
    Address(label: label, line1: line1, latitude: lat, longitude: -1.62);

void main() {
  const ama = AppUser(uid: 'ama', email: 'ama@example.com');
  final home = address('Home', '12 Prempeh II St');
  final work = address('Work', 'KNUST campus');

  late MockAddressBookRepository repository;

  setUp(() {
    repository = MockAddressBookRepository();
    when(() => repository.save(any(), any())).thenAnswer((_) async {});
  });

  Future<AddressBookProvider> signedIn(List<Address> saved) async {
    when(() => repository.load('ama')).thenAnswer((_) async => saved);
    final provider = AddressBookProvider(repository)..onAuthChanged(ama);
    await pumpEventQueue();
    return provider;
  }

  test('loads the saved addresses after sign-in', () async {
    final provider = await signedIn([home, work]);

    expect(provider.state, ViewState.success);
    expect(provider.addresses, [home, work]);
  });

  test('an empty book is the empty state', () async {
    final provider = await signedIn([]);

    expect(provider.state, ViewState.empty);
  });

  test('add puts the address first and replaces a duplicate', () async {
    final provider = await signedIn([home, work]);
    final movedHome = address('home', '12 PREMPEH II ST', lat: 6.7);

    await provider.add(movedHome);

    expect(provider.addresses, [movedHome, work]);
    verify(() => repository.save('ama', [movedHome, work])).called(1);
  });

  test('keeps only the newest ten', () async {
    final provider = await signedIn([
      for (var i = 0; i < AddressBookProvider.maxAddresses; i++)
        address('Spot $i', 'Line $i'),
    ]);

    await provider.add(home);

    expect(provider.addresses, hasLength(AddressBookProvider.maxAddresses));
    expect(provider.addresses.first, home);
    expect(provider.addresses.last.label, 'Spot 8');
  });

  test('remove deletes one address', () async {
    final provider = await signedIn([home, work]);

    await provider.remove(home);

    expect(provider.addresses, [work]);
  });

  test('a failed save rolls back and explains why', () async {
    final provider = await signedIn([home]);
    when(() => repository.save(any(), any()))
        .thenThrow(const NetworkException());

    final ok = await provider.remove(home);

    expect(ok, isFalse);
    expect(provider.addresses, [home]);
    expect(provider.errorMessage, const NetworkException().message);
  });

  test('signing out forgets the addresses', () async {
    final provider = await signedIn([home]);

    provider.onAuthChanged(null);

    expect(provider.addresses, isEmpty);
    expect(provider.state, ViewState.idle);
  });
}
