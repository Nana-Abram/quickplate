import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/order_tracking_provider.dart';

/// Shown only while the order is still "placed". Asks before cancelling.
class CancelOrderButton extends StatelessWidget {
  const CancelOrderButton({super.key});

  Future<void> _cancel(BuildContext context) async {
    final tracker = context.read<OrderTrackingProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel this order?'),
        content: const Text(
          'The restaurant has not accepted it yet, so nothing will be charged.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep order'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Cancel order'),
          ),
        ],
      ),
    );
    if (!(confirmed ?? false)) return;

    final ok = await tracker.cancel();
    if (!ok) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(tracker.actionError ?? 'Could not cancel the order.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUpdating = context.select<OrderTrackingProvider, bool>(
      (p) => p.isUpdating,
    );
    final scheme = Theme.of(context).colorScheme;

    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: scheme.error,
        side: BorderSide(color: scheme.error),
      ),
      onPressed: isUpdating ? null : () => _cancel(context),
      icon: const Icon(Icons.close),
      label: const Text('Cancel order'),
    );
  }
}
