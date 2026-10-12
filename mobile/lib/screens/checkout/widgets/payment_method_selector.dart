import 'package:flutter/material.dart';

import '../../../data/models/payment_method.dart';

class PaymentMethodSelector extends StatelessWidget {
  const PaymentMethodSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final PaymentMethod value;
  final ValueChanged<PaymentMethod> onChanged;

  static const _subtitles = {
    PaymentMethod.cashOnDelivery: 'Pay the rider when your food arrives.',
    PaymentMethod.mockCard: 'Demo only. No card is charged.',
  };

  static const _icons = {
    PaymentMethod.cashOnDelivery: Icons.payments_outlined,
    PaymentMethod.mockCard: Icons.credit_card,
  };

  @override
  Widget build(BuildContext context) {
    return Card.outlined(
      child: RadioGroup<PaymentMethod>(
        groupValue: value,
        onChanged: (method) {
          if (method != null) onChanged(method);
        },
        child: Column(
          children: [
            for (final method in PaymentMethod.values)
              RadioListTile<PaymentMethod>(
                value: method,
                secondary: Icon(_icons[method]),
                title: Text(method.label),
                subtitle: Text(_subtitles[method]!),
              ),
          ],
        ),
      ),
    );
  }
}
