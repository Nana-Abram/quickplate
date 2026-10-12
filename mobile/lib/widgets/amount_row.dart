import 'package:flutter/material.dart';

import '../core/utils/money.dart';

/// "Subtotal ........ GH₵90.00" row for totals.
class AmountRow extends StatelessWidget {
  const AmountRow({
    super.key,
    required this.label,
    required this.pesewas,
    this.isFee = false,
    this.emphasize = false,
  });

  final String label;
  final int pesewas;

  /// Shows 0 as "Free".
  final bool isFee;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final style = emphasize ? text.titleMedium : text.bodyLarge;
    final value = isFee ? Money.formatFee(pesewas) : Money.format(pesewas);

    // The label gives way so large text sizes never push the amount off
    // screen.
    return Row(
      children: [
        Expanded(child: Text(label, style: style)),
        const SizedBox(width: 16),
        Text(value, style: style),
      ],
    );
  }
}
