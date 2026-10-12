import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/constants/map_config.dart';
import '../../../data/models/address.dart';
import '../../../widgets/map_attribution.dart';

/// Small, static map with a pin on the delivery address.
class DeliveryMap extends StatelessWidget {
  const DeliveryMap({super.key, required this.address});

  final Address address;

  @override
  Widget build(BuildContext context) {
    final point = LatLng(address.latitude, address.longitude);

    return Semantics(
      label: 'Map of the delivery address',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: 180,
          child: FlutterMap(
            options: MapOptions(
              initialCenter: point,
              initialZoom: MapConfig.defaultZoom,
              // Read-only: it sits inside a scrolling list.
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.none,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: MapConfig.tileUrl,
                userAgentPackageName: MapConfig.userAgentPackageName,
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: point,
                    width: 48,
                    height: 48,
                    alignment: Alignment.topCenter,
                    child: Icon(
                      Icons.location_on,
                      size: 48,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const MapAttribution(),
            ],
          ),
        ),
      ),
    );
  }
}
