import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../core/errors/app_exception.dart';

/// Reads the device location, asking for permission when needed. Every
/// failure becomes a [LocationException] the user can act on; the map picker
/// always works without location.
class LocationService {
  Future<LatLng> currentLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocationException(
        'Location is turned off. Turn it on, or move the map to your address.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    switch (permission) {
      case LocationPermission.denied:
        throw const LocationException(
          'Without location access, move the map to your address instead.',
        );
      case LocationPermission.deniedForever:
        throw const LocationException(
          'Location access is off for QuickPlate. Allow it in Settings, '
          'or move the map to your address.',
          canOpenSettings: true,
        );
      case LocationPermission.whileInUse:
      case LocationPermission.always:
      case LocationPermission.unableToDetermine:
        break;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          timeLimit: Duration(seconds: 15),
        ),
      );
      return LatLng(position.latitude, position.longitude);
    } on TimeoutException {
      throw const LocationException(
        'Could not find your location. Move the map to your address instead.',
      );
    } on LocationServiceDisabledException {
      throw const LocationException(
        'Location is turned off. Turn it on, or move the map to your address.',
      );
    }
  }

  Future<bool> openSettings() => Geolocator.openAppSettings();
}
