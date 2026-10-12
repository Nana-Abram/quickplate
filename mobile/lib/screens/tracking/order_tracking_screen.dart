import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/routes.dart';
import '../../widgets/empty_view.dart';

/// Confirmation shown after checkout. Phase 7 replaces it with live tracking.
class OrderTrackingScreen extends StatelessWidget {
  const OrderTrackingScreen({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your order')),
      body: EmptyView(
        icon: Icons.check_circle_outline,
        title: 'Order placed',
        message: 'Order $orderId has been sent to the restaurant.',
        actionLabel: 'Back to restaurants',
        onAction: () => context.go(Routes.home),
      ),
    );
  }
}
