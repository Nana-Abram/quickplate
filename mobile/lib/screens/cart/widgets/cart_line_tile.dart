import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/cart_item.dart';
import '../../../providers/cart_provider.dart';
import '../../../widgets/price_text.dart';
import '../../../widgets/quantity_stepper.dart';

/// One cart line: swipe to remove, or adjust the quantity.
class CartLineTile extends StatelessWidget {
  const CartLineTile({super.key, required this.line});

  final CartItem line;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cart = context.read<CartProvider>();

    return Dismissible(
      key: ValueKey(line.key),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        color: theme.colorScheme.errorContainer,
        child: Icon(
          Icons.delete_outline,
          color: theme.colorScheme.onErrorContainer,
        ),
      ),
      onDismissed: (_) {
        cart.removeItem(line.key);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Removed ${line.name}.')));
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(line.name, style: theme.textTheme.titleSmall),
                ),
                const SizedBox(width: 12),
                PriceText(line.lineTotalPesewas),
              ],
            ),
            if (line.notes.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Note: ${line.notes}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            const SizedBox(height: 8),
            QuantityStepper(
              quantity: line.quantity,
              itemName: line.name,
              decrementIcon: line.quantity == 1
                  ? Icons.delete_outline
                  : Icons.remove,
              onDecrement: () => cart.decrement(line.key),
              onIncrement: line.quantity < CartProvider.maxQuantity
                  ? () => cart.increment(line.key)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
