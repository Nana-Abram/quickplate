import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/constants/routes.dart';
import '../data/models/push_message.dart';
import '../providers/notification_provider.dart';

/// Connects push notifications to the UI: a banner for pushes that arrive
/// while the app is open, and opening the order when a notification is
/// tapped (from the background or from a cold start).
class PushMessageHandler extends StatefulWidget {
  const PushMessageHandler({
    super.key,
    required this.router,
    required this.messengerKey,
    required this.child,
  });

  final GoRouter router;
  final GlobalKey<ScaffoldMessengerState> messengerKey;
  final Widget child;

  @override
  State<PushMessageHandler> createState() => _PushMessageHandlerState();
}

class _PushMessageHandlerState extends State<PushMessageHandler> {
  final List<StreamSubscription<PushMessage>> _subscriptions = [];

  @override
  void initState() {
    super.initState();
    // Reading the provider here also creates it, which starts device
    // registration as soon as a user is signed in.
    final notifications = context.read<NotificationProvider>();
    _subscriptions
      ..add(notifications.onForegroundMessage.listen(_showBanner))
      ..add(notifications.onMessageOpenedApp.listen(_openOrder));
    unawaited(_openInitialMessage(notifications));
  }

  Future<void> _openInitialMessage(NotificationProvider notifications) async {
    final message = await notifications.getInitialMessage();
    final orderId = message?.orderId;
    // go, not push: after a cold start this is the only screen. The router
    // holds it on the splash until the session is restored.
    if (orderId != null && mounted) {
      widget.router.go(Routes.orderById(orderId));
    }
  }

  void _openOrder(PushMessage message) {
    final orderId = message.orderId;
    if (orderId != null) {
      unawaited(widget.router.push(Routes.orderById(orderId)));
    }
  }

  void _showBanner(PushMessage message) {
    final text = [message.title, message.body].nonNulls.join(': ');
    if (text.isEmpty) return;
    widget.messengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(text),
        persist: false,
        action: message.orderId == null
            ? null
            : SnackBarAction(
                label: 'View',
                onPressed: () => _openOrder(message),
              ),
      ),
    );
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
