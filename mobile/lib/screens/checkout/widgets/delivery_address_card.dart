import 'package:flutter/material.dart';

import '../../../data/models/address.dart';

/// The chosen delivery address, or a prompt to choose one.
class DeliveryAddressCard extends StatelessWidget {
  const DeliveryAddressCard({
    super.key,
    required this.address,
    required this.onTap,
  });

  final Address? address;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final chosen = address;

    return Card.outlined(
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Icon(
          chosen == null ? Icons.add_location_alt_outlined : Icons.location_on,
          color: scheme.primary,
        ),
        title: Text(chosen?.label ?? 'Choose a delivery address'),
        subtitle: Text(chosen?.line1 ?? 'Pick the spot on the map'),
        trailing: Text(chosen == null ? 'Choose' : 'Change'),
      ),
    );
  }
}
