import 'package:flutter/material.dart';

import '../../../data/models/address.dart';

/// What the user picked in the address chooser.
sealed class AddressChoice {
  const AddressChoice();
}

class SavedAddressChoice extends AddressChoice {
  const SavedAddressChoice(this.address);

  final Address address;
}

class PickOnMapChoice extends AddressChoice {
  const PickOnMapChoice();
}

/// Lists saved addresses with a "new address" option at the bottom.
Future<AddressChoice?> showAddressChooser(
  BuildContext context, {
  required List<Address> saved,
}) {
  return showModalBottomSheet<AddressChoice>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: Text(
              'Deliver to',
              style: Theme.of(sheetContext).textTheme.titleMedium,
            ),
          ),
          for (final address in saved)
            ListTile(
              leading: const Icon(Icons.location_on_outlined),
              title: Text(address.label),
              subtitle: Text(address.line1),
              onTap: () =>
                  Navigator.of(sheetContext).pop(SavedAddressChoice(address)),
            ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.add_location_alt_outlined),
            title: const Text('Choose a new address on the map'),
            onTap: () =>
                Navigator.of(sheetContext).pop(const PickOnMapChoice()),
          ),
        ],
      ),
    ),
  );
}
