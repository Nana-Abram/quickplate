import 'package:flutter/material.dart';

import '../../../data/models/order.dart';
import '../../../widgets/amount_row.dart';
import '../../../widgets/price_text.dart';

/// What was ordered and what it cost, as priced by the server.
class OrderItemsCard extends StatelessWidget {
  const OrderItemsCard({super.key, required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final item in order.items)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${item.quantity} × ${item.name}'),
                          if (item.notes.isNotEmpty)
                            Text(
                              'Note: ${item.notes}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    PriceText(item.lineTotalPesewas),
                  ],
                ),
              ),
            const Divider(height: 12),
            const SizedBox(height: 8),
            AmountRow(label: 'Subtotal', pesewas: order.subtotalPesewas),
            const SizedBox(height: 8),
            AmountRow(
              label: 'Delivery fee',
              pesewas: order.deliveryFeePesewas,
              isFee: true,
            ),
            const Divider(height: 24),
            AmountRow(
              label: 'Total',
              pesewas: order.totalPesewas,
              emphasize: true,
            ),
            const SizedBox(height: 8),
            Text(
              'Payment: ${order.paymentMethod.label}',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
