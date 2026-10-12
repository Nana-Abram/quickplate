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

    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      minimum: const EdgeInsets.all(16),
      child: FilledButton(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(60),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
        onPressed: () => context.push(Routes.cart),
        child: Row(
          children: [
            Semantics(
              label: count == 1 ? '1 item' : '$count items',
              excludeSemantics: true,
              child: Container(
                constraints: const BoxConstraints(minWidth: 36),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: scheme.onPrimary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('$count', textAlign: TextAlign.center),
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(child: Text('View cart')),
            Text(Money.format(subtotal)),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}
