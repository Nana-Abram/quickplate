import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/routes.dart';
import '../../core/utils/money.dart';
import '../../data/models/address.dart';
import '../../data/models/payment_method.dart';
import '../../providers/cart_provider.dart';
import '../../providers/orders_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/empty_view.dart';
import '../cart/widgets/cart_summary.dart';
import 'widgets/delivery_address_card.dart';
import 'widgets/payment_method_selector.dart';
import 'widgets/place_order_error.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  Address? _address;
  PaymentMethod _paymentMethod = PaymentMethod.cashOnDelivery;

  @override
  void initState() {
    super.initState();
    // An error from an earlier attempt should not greet a new checkout.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<OrdersProvider>().clearPlaceOrderError();
    });
  }

  Future<void> _pickAddress() async {
    final address = await context.push<Address>(
      Routes.addressPicker,
      extra: _address,
    );
    if (address != null && mounted) setState(() => _address = address);
  }

  Future<void> _placeOrder() async {
    final cart = context.read<CartProvider>();
    final address = _address;
    final restaurant = cart.restaurant;
    if (address == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose a delivery address first.')),
      );
      return;
    }
    if (restaurant == null) return;

    final order = await context.read<OrdersProvider>().placeOrder(
      restaurantId: restaurant.id,
      items: cart.items,
      deliveryAddress: address,
      paymentMethod: _paymentMethod,
    );
    if (order == null || !mounted) return;

    // Leave checkout before emptying the cart, so it never flashes empty.
    context.go(Routes.orderById(order.id));
    cart.clear();
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final isPlacing = context.select<OrdersProvider, bool>(
      (p) => p.isPlacingOrder,
    );
    final text = Theme.of(context).textTheme;

    if (cart.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Checkout')),
        body: EmptyView(
          icon: Icons.shopping_bag_outlined,
          title: 'Your cart is empty',
          actionLabel: 'Browse restaurants',
          onAction: () => context.go(Routes.home),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Deliver to', style: text.titleMedium),
          const SizedBox(height: 8),
          DeliveryAddressCard(address: _address, onTap: _pickAddress),
          const SizedBox(height: 24),
          Text('Payment', style: text.titleMedium),
          const SizedBox(height: 8),
          PaymentMethodSelector(
            value: _paymentMethod,
            onChanged: (method) => setState(() => _paymentMethod = method),
          ),
          const SizedBox(height: 24),
          Text(
            '${cart.restaurant?.name} · ${cart.itemCount} items',
            style: text.titleMedium,
          ),
          const SizedBox(height: 8),
          const CartSummary(),
          const SizedBox(height: 8),
          Text(
            'The restaurant confirms the final price when you place the order.',
            style: text.bodySmall,
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const PlaceOrderError(),
            AppButton(
              label: 'Place order · ${Money.format(cart.totalPesewas)}',
              isLoading: isPlacing,
              onPressed: _placeOrder,
            ),
          ],
        ),
      ),
    );
  }
}
