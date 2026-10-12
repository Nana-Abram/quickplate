import 'package:flutter/material.dart';

/// Asks before replacing a cart that holds another restaurant's dishes.
/// Returns true only if the user chose to start a new cart.
Future<bool> confirmReplaceCart(
  BuildContext context, {
  required String currentRestaurant,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Start a new cart?'),
      content: Text(
        'Your cart has dishes from $currentRestaurant. You can only order '
        'from one restaurant at a time, so they will be removed.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Keep cart'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Start new cart'),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
