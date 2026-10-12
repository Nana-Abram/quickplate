import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/routes.dart';
import '../../data/models/order.dart';
import '../../providers/order_tracking_provider.dart';
import '../../providers/view_state.dart';
import '../../widgets/error_view.dart';
import '../../widgets/shimmer_list.dart';
import '../../widgets/status_timeline.dart';
import 'widgets/cancel_order_button.dart';
import 'widgets/delivery_map.dart';
import 'widgets/order_items_card.dart';
import 'widgets/tracking_header.dart';

/// Live status of one order, plus its details. Also serves as the order
/// detail screen for finished orders.
class OrderTrackingScreen extends StatelessWidget {
  const OrderTrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.select<OrderTrackingProvider, ViewState>(
      (p) => p.state,
    );
    final order = context.select<OrderTrackingProvider, Order?>((p) => p.order);
    final provider = context.read<OrderTrackingProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your order'),
        // Checkout replaces the stack with this screen, so offer a way home.
        leading: context.canPop()
            ? null
            : IconButton(
                tooltip: 'Home',
                icon: const Icon(Icons.home_outlined),
                onPressed: () => context.go(Routes.home),
              ),
      ),
      body: switch (state) {
        ViewState.error => ErrorView(
          message: provider.errorMessage ?? 'Something went wrong.',
          onRetry: provider.load,
        ),
        ViewState.success when order != null => _OrderDetails(order: order),
        _ => const ShimmerList(itemHeight: 64),
      },
    );
  }
}

class _OrderDetails extends StatelessWidget {
  const _OrderDetails({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final isLive = context.select<OrderTrackingProvider, bool>((p) => p.isLive);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TrackingHeader(order: order),
        if (!isLive && !order.status.isFinal)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Live updates are paused. Refreshing every few seconds.',
              style: text.bodySmall,
            ),
          ),
        const SizedBox(height: 16),
        Card.outlined(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: StatusTimeline(
              status: order.status,
              history: order.statusHistory,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text('Delivering to', style: text.titleMedium),
        const SizedBox(height: 8),
        DeliveryMap(address: order.deliveryAddress),
        const SizedBox(height: 8),
        Text(
          '${order.deliveryAddress.label} · ${order.deliveryAddress.line1}',
          style: text.bodyMedium,
        ),
        const SizedBox(height: 24),
        Text(order.restaurantName, style: text.titleMedium),
        const SizedBox(height: 8),
        OrderItemsCard(order: order),
        if (order.status.canCancel) ...[
          const SizedBox(height: 24),
          const CancelOrderButton(),
        ],
      ],
    );
  }
}
