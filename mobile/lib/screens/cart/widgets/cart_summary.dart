import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/cart_provider.dart';
import '../../../widgets/amount_row.dart';

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

    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            AmountRow(label: 'Subtotal', pesewas: subtotal),
            const SizedBox(height: 8),
            AmountRow(label: 'Delivery fee', pesewas: fee, isFee: true),
            const Divider(height: 24),
            AmountRow(label: 'Total', pesewas: total, emphasize: true),
          ],
        ),
      ),
    );
  }
}
