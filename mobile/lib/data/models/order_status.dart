/// Order lifecycle: placed -> accepted -> preparing -> on_the_way ->
/// delivered, or placed -> cancelled.
enum OrderStatus {
  placed('placed', 'Order placed'),
  accepted('accepted', 'Accepted'),
  preparing('preparing', 'Preparing'),
  onTheWay('on_the_way', 'On the way'),
  delivered('delivered', 'Delivered'),
  cancelled('cancelled', 'Cancelled');

  const OrderStatus(this.apiValue, this.label);

  final String apiValue;
  final String label;

  /// The happy path, in order, for timelines.
  static const List<OrderStatus> flow = [
    placed,
    accepted,
    preparing,
    onTheWay,
    delivered,
  ];

  bool get isFinal => this == delivered || this == cancelled;

  /// Only orders the restaurant has not accepted yet can be cancelled.
  bool get canCancel => this == placed;

  static OrderStatus fromApi(String value) {
    return values.firstWhere(
      (status) => status.apiValue == value,
      orElse: () => throw FormatException('Unknown order status: $value'),
    );
  }
}
