import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../data/models/order.dart';
import '../../../data/models/order_status.dart';
import '../../../providers/order_tracking_provider.dart';

/// Big status line and arrival estimate. In debug builds a long press moves
/// the order to its next status, so a demo need not wait for the simulator.
class TrackingHeader extends StatelessWidget {
  const TrackingHeader({super.key, required this.order});

  final Order order;

  static String _headline(OrderStatus status) => switch (status) {
    OrderStatus.placed => 'Waiting for the restaurant',
    OrderStatus.accepted => 'Order accepted',
    OrderStatus.preparing => 'Preparing your food',
    OrderStatus.onTheWay => 'On the way to you',
    OrderStatus.delivered => 'Delivered',
    OrderStatus.cancelled => 'Order cancelled',
  };

  Future<void> _advanceForDemo(BuildContext context) async {
    final tracker = context.read<OrderTrackingProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final ok = await tracker.advance();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Demo: moved to "${tracker.order?.status.label}".'
              : tracker.actionError ?? 'Could not advance the order.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final eta = context.select<OrderTrackingProvider, DateTime?>(
      (p) => p.estimatedArrival,
    );
    final subtitle = switch (order.status) {
      OrderStatus.delivered => 'Enjoy your meal!',
      OrderStatus.cancelled => 'You have not been charged.',
      _ when eta != null =>
        'Arriving around ${DateFormat.jm().format(eta.toLocal())}',
      _ => '',
    };

    return GestureDetector(
      onLongPress: kDebugMode ? () => _advanceForDemo(context) : null,
      child: Semantics(
        header: true,
        liveRegion: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_headline(order.status), style: text.headlineSmall),
            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(subtitle, style: text.bodyLarge),
            ],
          ],
        ),
      ),
    );
  }
}
