import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/orders_provider.dart';

/// Why the last order attempt failed, e.g. a dish that just sold out.
class PlaceOrderError extends StatelessWidget {
  const PlaceOrderError({super.key});

  @override
  Widget build(BuildContext context) {
    final message = context.select<OrdersProvider, String?>(
      (p) => p.placeOrderError,
    );
    if (message == null) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: scheme.errorContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(message, style: TextStyle(color: scheme.onErrorContainer)),
      ),
    );
  }
}
