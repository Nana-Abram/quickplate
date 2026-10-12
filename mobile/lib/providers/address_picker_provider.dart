import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import '../core/errors/app_exception.dart';
import '../data/models/address.dart';
import '../data/services/location_service.dart';
import 'view_state.dart';

/// State for the map address picker. Created with the picker screen.
class AddressPickerProvider extends ChangeNotifier {
  AddressPickerProvider(this._locationService, {required LatLng initialCenter})
    : _center = initialCenter;

  final LocationService _locationService;

  LatLng _center;
  ViewState _locateState = ViewState.idle;
  String? _locateError;
  bool _canOpenSettings = false;
  bool _disposed = false;

  /// The point under the pin.
  LatLng get center => _center;
  bool get isLocating => _locateState == ViewState.loading;
  String? get locateError => _locateError;
  bool get canOpenSettings => _canOpenSettings;

  /// Follows the map as it moves. Not notified: nothing on screen depends on
  /// it, and it changes on every frame of a drag.
  void updateCenter(LatLng center) => _center = center;

  /// Finds the device location. Returns it so the screen can move the map,
  /// or null with [locateError] set.
  Future<LatLng?> locate() async {
    if (isLocating) return null;
    _locateState = ViewState.loading;
    _locateError = null;
    _canOpenSettings = false;
    notifyListeners();

    try {
      final location = await _locationService.currentLocation();
      _center = location;
      _locateState = ViewState.success;
      return location;
    } on LocationException catch (error) {
      _locateError = error.message;
      _canOpenSettings = error.canOpenSettings;
      _locateState = ViewState.error;
      return null;
    } finally {
      notifyListeners();
    }
  }

  Future<void> openSettings() => _locationService.openSettings();

  Address buildAddress({required String label, required String line1}) {
    final trimmedLabel = label.trim();
    return Address(
      label: trimmedLabel.isEmpty ? 'Home' : trimmedLabel,
      line1: line1.trim(),
      latitude: _center.latitude,
      longitude: _center.longitude,
    );
  }

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
