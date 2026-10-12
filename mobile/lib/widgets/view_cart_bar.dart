import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/constants/routes.dart';
import '../core/utils/money.dart';
import '../providers/cart_provider.dart';

/// Bottom bar on a restaurant's menu once its dishes are in the cart.
class ViewCartBar extends StatelessWidget {
  const ViewCartBar({super.key, required this.restaurantId});

  final String restaurantId;

  @override
  Widget build(BuildContext context) {
    final (count, subtotal, cartRestaurantId) = context
        .select<CartProvider, (int, int, String?)>(
          (c) => (c.itemCount, c.subtotalPesewas, c.restaurant?.id),
        );
    if (count == 0 || cartRestaurantId != restaurantId) {
      return const SizedBox.shrink();
    }

    return SafeArea(
      minimum: const EdgeInsets.all(16),
      child: FilledButton(
        onPressed: () => context.push(Routes.cart),
        child: Row(
          children: [
            Badge.count(
              count: count,
              child: const Icon(Icons.shopping_bag_outlined),
            ),
            const SizedBox(width: 16),
            const Expanded(child: Text('View cart')),
            Text(Money.format(subtotal)),
          ],
        ),
      ),
    );
  }
}
