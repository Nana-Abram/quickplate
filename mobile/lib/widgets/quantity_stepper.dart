import 'package:flutter/material.dart';

/// Minus / count / plus control with 48dp tap targets. A null callback
/// disables that button.
class QuantityStepper extends StatelessWidget {
  const QuantityStepper({
    super.key,
    required this.quantity,
    required this.onDecrement,
    required this.onIncrement,
    this.itemName,
    this.decrementIcon = Icons.remove,
  });

  final int quantity;
  final VoidCallback? onDecrement;
  final VoidCallback? onIncrement;

  /// Used in tooltips, e.g. "Remove one Jollof Rice".
  final String? itemName;

  /// Lets the cart show a bin icon when one more tap removes the line.
  final IconData decrementIcon;

  @override
  Widget build(BuildContext context) {
    final suffix = itemName == null ? '' : ' $itemName';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton.outlined(
          tooltip: 'Remove one$suffix',
          icon: Icon(decrementIcon),
          onPressed: onDecrement,
        ),
        SizedBox(
          width: 40,
          child: Text(
            '$quantity',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
            semanticsLabel: 'Quantity $quantity',
          ),
        ),
        IconButton.outlined(
          tooltip: 'Add one$suffix',
          icon: const Icon(Icons.add),
          onPressed: onIncrement,
        ),
      ],
    );
  }
}
