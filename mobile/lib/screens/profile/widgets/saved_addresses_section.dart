import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/address.dart';
import '../../../providers/address_book_provider.dart';
import '../../../providers/view_state.dart';

/// The saved address list, in each of its states. Addresses are added from
/// the map picker at checkout; here they can only be removed.
class SavedAddressesSection extends StatelessWidget {
  const SavedAddressesSection({super.key});

  Future<void> _remove(BuildContext context, Address address) async {
    final book = context.read<AddressBookProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final ok = await book.remove(address);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Removed ${address.label}.'
              : book.errorMessage ?? 'Could not remove the address.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final book = context.watch<AddressBookProvider>();
    final muted = Theme.of(context).textTheme.bodyMedium
        ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant);

    return switch (book.state) {
      ViewState.idle || ViewState.loading => const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      ),
      ViewState.error => ListTile(
        leading: const Icon(Icons.error_outline),
        title: Text(book.errorMessage ?? 'Could not load your addresses.'),
        trailing: TextButton(onPressed: book.load, child: const Text('Retry')),
      ),
      ViewState.empty => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text(
          'No saved addresses yet. Addresses you pick at checkout are '
          'saved here.',
          style: muted,
        ),
      ),
      ViewState.success => Column(
        children: [
          for (final address in book.addresses)
            ListTile(
              leading: const Icon(Icons.location_on_outlined),
              title: Text(address.label),
              subtitle: Text(address.line1),
              trailing: IconButton(
                tooltip: 'Remove ${address.label}',
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _remove(context, address),
              ),
            ),
        ],
      ),
    };
  }
}
