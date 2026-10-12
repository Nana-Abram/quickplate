import 'package:flutter/material.dart';

import '../core/utils/money.dart';

/// Shows an amount stored in pesewas as cedis.
class PriceText extends StatelessWidget {
  const PriceText(this.pesewas, {super.key, this.style});

  final int pesewas;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Text(
      Money.format(pesewas),
      style: style ?? Theme.of(context).textTheme.titleSmall,
    );
  }
}
