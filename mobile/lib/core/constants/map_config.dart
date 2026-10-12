import 'package:latlong2/latlong.dart';

/// OpenStreetMap tiles: free and keyless, but the tile usage policy asks
/// every app to identify itself and show attribution.
abstract final class MapConfig {
  static const String tileUrl =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const String userAgentPackageName = 'com.abraham.quickplate';
  static const String attribution = 'OpenStreetMap contributors';

  /// Kumasi city centre, used when there is nothing better to start from.
  static const LatLng defaultCenter = LatLng(6.6885, -1.6244);
  static const double defaultZoom = 16;
  static const double locatedZoom = 17;
}
