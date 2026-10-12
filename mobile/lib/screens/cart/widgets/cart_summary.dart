import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/money.dart';
import '../../../providers/cart_provider.dart';

/// Subtotal, delivery fee and total. These are estimates from menu prices;
/// the server computes the charged total when the order is placed.
class CartSummary extends StatelessWidget {
  const CartSummary({super.key});

  @override
  Widget build(BuildContext context) {
    final (subtotal, fee, total) = context
        .select<CartProvider, (int, int, int)>(
          (c) => (c.subtotalPesewas, c.deliveryFeePesewas, c.totalPesewas),
        );
    final text = Theme.of(context).textTheme;

    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _Row(label: 'Subtotal', value: Money.format(subtotal)),
            const SizedBox(height: 8),
            _Row(label: 'Delivery fee', value: Money.formatFee(fee)),
            const Divider(height: 24),
            _Row(
              label: 'Total',
              value: Money.format(total),
              style: text.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value, this.style});

  final String label;
  final String value;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final textStyle = style ?? Theme.of(context).textTheme.bodyLarge;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: textStyle),
        Text(value, style: textStyle),
      ],
    );
  }
}
