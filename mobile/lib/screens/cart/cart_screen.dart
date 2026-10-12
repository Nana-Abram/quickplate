import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/routes.dart';
import '../../data/models/cart_item.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/empty_view.dart';
import 'widgets/cart_line_tile.dart';
import 'widgets/cart_summary.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  Future<void> _confirmClear(BuildContext context) async {
    final cart = context.read<CartProvider>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Clear your cart?'),
        content: const Text('All dishes will be removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Clear cart'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) cart.clear();
  }

  @override
  Widget build(BuildContext context) {
    final items = context.select<CartProvider, List<CartItem>>((c) => c.items);
    final restaurantName = context.select<CartProvider, String?>(
      (c) => c.restaurant?.name,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your cart'),
        actions: [
          if (items.isNotEmpty)
            TextButton(
              onPressed: () => _confirmClear(context),
              child: const Text('Clear cart'),
            ),
        ],
      ),
      body: items.isEmpty
          ? EmptyView(
              icon: Icons.shopping_bag_outlined,
              title: 'Your cart is empty',
              message: 'Add dishes from a restaurant to get started.',
              actionLabel: 'Browse restaurants',
              onAction: () => context.go(Routes.home),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                if (restaurantName != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      restaurantName,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                for (final line in items) CartLineTile(line: line),
                const SizedBox(height: 16),
                const CartSummary(),
              ],
            ),
    );
  }
}
