import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/routes.dart';
import '../../providers/orders_provider.dart';
import '../../providers/view_state.dart';
import '../../widgets/empty_view.dart';
import '../../widgets/error_view.dart';
import '../../widgets/shimmer_list.dart';
import 'widgets/order_card.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  @override
  void initState() {
    super.initState();
    // Reload on every visit: statuses change while the user is elsewhere.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<OrdersProvider>().loadOrders(keepVisible: true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OrdersProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Your orders')),
      body: switch (provider.historyState) {
        ViewState.idle ||
        ViewState.loading => const ShimmerList(itemHeight: 72),
        ViewState.error => ErrorView(
          message: provider.historyError ?? 'Something went wrong.',
          onRetry: provider.loadOrders,
        ),
        ViewState.empty => EmptyView(
          icon: Icons.receipt_long_outlined,
          title: 'No orders yet',
          message: 'Your orders will show up here.',
          actionLabel: 'Browse restaurants',
          onAction: () => context.go(Routes.home),
        ),
        ViewState.success => RefreshIndicator(
          onRefresh: () => provider.loadOrders(keepVisible: true),
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: provider.orders.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final order = provider.orders[index];
              return OrderCard(
                order: order,
                onTap: () => context.push(Routes.orderById(order.id)),
              );
            },
          ),
        ),
      },
    );
  }
}
