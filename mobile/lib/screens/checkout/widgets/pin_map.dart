import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/constants/map_config.dart';
import '../../../widgets/map_attribution.dart';

/// Map with a pin fixed at its centre. Dragging the map or tapping a spot
/// moves the location under the pin.
class PinMap extends StatelessWidget {
  const PinMap({
    super.key,
    required this.controller,
    required this.initialCenter,
    required this.onCenterChanged,
    required this.onLocate,
    required this.isLocating,
  });

  final MapController controller;
  final LatLng initialCenter;
  final ValueChanged<LatLng> onCenterChanged;
  final VoidCallback onLocate;
  final bool isLocating;

  static const double _pinSize = 48;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Stack(
      children: [
        FlutterMap(
          mapController: controller,
          options: MapOptions(
            initialCenter: initialCenter,
            initialZoom: MapConfig.defaultZoom,
            onTap: (_, point) => controller.move(point, controller.camera.zoom),
            onPositionChanged: (camera, _) => onCenterChanged(camera.center),
          ),
          children: [
            TileLayer(
              urlTemplate: MapConfig.tileUrl,
              userAgentPackageName: MapConfig.userAgentPackageName,
            ),
            const MapAttribution(),
          ],
        ),
        IgnorePointer(
          child: Center(
            // Lift the icon so its tip, not its middle, marks the centre.
            child: Transform.translate(
              offset: const Offset(0, -_pinSize / 2),
              child: Icon(
                Icons.location_on,
                size: _pinSize,
                color: scheme.primary,
                semanticLabel: 'Delivery pin',
              ),
            ),
          ),
        ),
        Positioned(
          top: 12,
          left: 12,
          right: 12,
          child: Center(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Text(
                  'Move the map or tap to place the pin',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
            ),
          ),
        ),
        Positioned(
          right: 16,
          bottom: 40,
          child: FloatingActionButton(
            heroTag: null,
            tooltip: 'Use my location',
            onPressed: isLocating ? null : onLocate,
            child: isLocating
                ? const SizedBox.square(
                    dimension: 24,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  )
                : const Icon(Icons.my_location),
          ),
        ),
      ],
    );
  }
}
