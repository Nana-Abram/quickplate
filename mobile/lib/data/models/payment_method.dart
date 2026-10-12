enum PaymentMethod {
  cashOnDelivery('cash_on_delivery', 'Cash on delivery'),

  /// No real payment is taken; it only demonstrates the flow.
  mockCard('mock_card', 'Card (demo)');

  const PaymentMethod(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static PaymentMethod fromApi(String value) {
    return values.firstWhere(
      (method) => method.apiValue == value,
      orElse: () => throw FormatException('Unknown payment method: $value'),
    );
  }
}
