import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/constants/routes.dart';
import '../providers/cart_provider.dart';

/// App bar cart button with a badge showing how many dishes are in the cart.
class CartIconButton extends StatelessWidget {
  const CartIconButton({super.key});

  @override
  Widget build(BuildContext context) {
    final count = context.select<CartProvider, int>((c) => c.itemCount);

    return IconButton(
      tooltip: count == 0 ? 'Cart' : 'Cart, $count items',
      onPressed: () => context.push(Routes.cart),
      // The tooltip already says how many items; without this the badge's
      // bare number replaces it for screen readers.
      icon: ExcludeSemantics(
        child: Badge.count(
          count: count,
          isLabelVisible: count > 0,
          child: const Icon(Icons.shopping_bag_outlined),
        ),
      ),
    );
  }
}
