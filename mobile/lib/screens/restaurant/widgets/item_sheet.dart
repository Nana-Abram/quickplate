import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/routes.dart';
import '../../../core/utils/money.dart';
import '../../../data/models/menu_item.dart';
import '../../../data/models/restaurant.dart';
import '../../../providers/cart_provider.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_network_image.dart';
import '../../../widgets/app_text_field.dart';
import '../../../widgets/quantity_stepper.dart';
import 'replace_cart_dialog.dart';

Future<void> showItemSheet(
  BuildContext context, {
  required Restaurant restaurant,
  required MenuItem item,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (_) => ItemSheet(restaurant: restaurant, item: item),
  );
}

/// Pick a quantity and add notes before adding a dish to the cart.
class ItemSheet extends StatefulWidget {
  const ItemSheet({super.key, required this.restaurant, required this.item});

  final Restaurant restaurant;
  final MenuItem item;

  @override
  State<ItemSheet> createState() => _ItemSheetState();
}

class _ItemSheetState extends State<ItemSheet> {
  final _notes = TextEditingController();
  int _quantity = 1;

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  Future<void> _addToCart() async {
    final cart = context.read<CartProvider>();
    AddToCartResult add({bool replaceCart = false}) => cart.addItem(
      restaurant: widget.restaurant,
      item: widget.item,
      quantity: _quantity,
      notes: _notes.text,
      replaceCart: replaceCart,
    );

    var result = add();
    if (result == AddToCartResult.differentRestaurant) {
      final replace = await confirmReplaceCart(
        context,
        currentRestaurant: cart.restaurant?.name ?? '',
      );
      if (!replace || !mounted) return;
      result = add(replaceCart: true);
    }
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    Navigator.of(context).pop();
    messenger.showSnackBar(
      SnackBar(
        // Snackbars with an action persist by default; this one is only a
        // shortcut, so let it time out.
        persist: false,
        content: Text(switch (result) {
          AddToCartResult.added => 'Added ${widget.item.name} to your cart.',
          AddToCartResult.cartFull => 'Your cart is full. Check out first.',
          _ => 'This dish cannot be ordered right now.',
        }),
        action: result == AddToCartResult.added
            ? SnackBarAction(
                label: 'View cart',
                onPressed: () => router.push(Routes.cart),
              )
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final item = widget.item;
    final canOrder = widget.restaurant.isOpen && item.isAvailable;

    return Padding(
      // Lift the sheet above the keyboard while typing notes.
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: AppNetworkImage(url: item.imageUrl),
              ),
            ),
            const SizedBox(height: 16),
            Text(item.name, style: theme.textTheme.titleLarge),
            if (item.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(item.description, style: theme.textTheme.bodyMedium),
            ],
            const SizedBox(height: 8),
            Text(
              Money.format(item.pricePesewas),
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Notes for the kitchen (optional)',
              hint: 'e.g. no onions, extra shito',
              controller: _notes,
              maxLength: 200,
              maxLines: 2,
              enabled: canOrder,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 8),
            Center(
              child: QuantityStepper(
                quantity: _quantity,
                itemName: item.name,
                onDecrement: canOrder && _quantity > 1
                    ? () => setState(() => _quantity--)
                    : null,
                onIncrement: canOrder && _quantity < CartProvider.maxQuantity
                    ? () => setState(() => _quantity++)
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            AppButton(
              label: canOrder
                  ? 'Add to cart · ${Money.format(item.pricePesewas * _quantity)}'
                  : widget.restaurant.isOpen
                  ? 'Unavailable right now'
                  : 'Restaurant is closed',
              onPressed: canOrder ? _addToCart : null,
            ),
          ],
        ),
      ),
    );
  }
}
