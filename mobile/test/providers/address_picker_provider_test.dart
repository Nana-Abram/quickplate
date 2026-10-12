import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quickplate/core/errors/app_exception.dart';
import 'package:quickplate/providers/address_picker_provider.dart';

import '../helpers/mocks.dart';

void main() {
  const kumasi = LatLng(6.6885, -1.6244);
  const accra = LatLng(5.556, -0.182);

  late MockLocationService locationService;

  setUp(() => locationService = MockLocationService());

  AddressPickerProvider picker() =>
      AddressPickerProvider(locationService, initialCenter: kumasi);

  test('starts at the given centre and follows the map', () {
    final provider = picker();
    expect(provider.center, kumasi);

    provider.updateCenter(accra);

    expect(provider.center, accra);
  });

  test('locate moves the centre to the device location', () async {
    when(() => locationService.currentLocation())
        .thenAnswer((_) async => accra);
    final provider = picker();

    final result = await provider.locate();

    expect(result, accra);
    expect(provider.center, accra);
    expect(provider.locateError, isNull);
    expect(provider.isLocating, isFalse);
  });

  test('a refused permission leaves the pin where it was', () async {
    when(() => locationService.currentLocation()).thenThrow(
      const LocationException('Location access is off.', canOpenSettings: true),
    );
    final provider = picker();

    final result = await provider.locate();

    expect(result, isNull);
    expect(provider.center, kumasi);
    expect(provider.locateError, 'Location access is off.');
    expect(provider.canOpenSettings, isTrue);
  });

  test('buildAddress uses the pin and trims the text', () {
    final provider = picker()..updateCenter(accra);

    final address = provider.buildAddress(label: '  ', line1: ' Oxford St ');

    expect(address.label, 'Home');
    expect(address.line1, 'Oxford St');
    expect(address.latitude, accra.latitude);
    expect(address.longitude, accra.longitude);
  });
}
