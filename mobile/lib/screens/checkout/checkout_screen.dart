import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/routes.dart';
import '../../core/utils/money.dart';
import '../../core/utils/text_format.dart';
import '../../data/models/address.dart';
import '../../data/models/payment_method.dart';
import '../../providers/address_book_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/orders_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/empty_view.dart';
import '../cart/widgets/cart_summary.dart';
import 'widgets/address_chooser_sheet.dart';
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

  /// The chosen address, or else the most recently saved one.
  Address? _effectiveAddress(BuildContext context) =>
      _address ??
      context.select<AddressBookProvider, Address?>(
        (p) => p.addresses.firstOrNull,
      );

  Future<void> _chooseAddress() async {
    final saved = context.read<AddressBookProvider>().addresses;
    final choice = saved.isEmpty
        ? const PickOnMapChoice()
        : await showAddressChooser(context, saved: saved);
    if (!mounted) return;
    switch (choice) {
      case SavedAddressChoice(:final address):
        setState(() => _address = address);
      case PickOnMapChoice():
        final address = await context.push<Address>(
          Routes.addressPicker,
          extra: _address,
        );
        if (address != null && mounted) setState(() => _address = address);
      case null:
        break;
    }
  }

  Future<void> _placeOrder() async {
    final cart = context.read<CartProvider>();
    final address =
        _address ?? context.read<AddressBookProvider>().addresses.firstOrNull;
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
    // Rebuild only for what this screen shows, not every cart change.
    final (isEmpty, restaurantName, itemCount, total) = context
        .select<CartProvider, (bool, String?, int, int)>(
          (c) => (c.isEmpty, c.restaurant?.name, c.itemCount, c.totalPesewas),
        );
    final isPlacing = context.select<OrdersProvider, bool>(
      (p) => p.isPlacingOrder,
    );
    final text = Theme.of(context).textTheme;

    if (isEmpty) {
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
          DeliveryAddressCard(
            address: _effectiveAddress(context),
            onTap: _chooseAddress,
          ),
          const SizedBox(height: 24),
          Text('Payment', style: text.titleMedium),
          const SizedBox(height: 8),
          PaymentMethodSelector(
            value: _paymentMethod,
            onChanged: (method) => setState(() => _paymentMethod = method),
          ),
          const SizedBox(height: 24),
          Text(
            '$restaurantName · ${TextFormat.itemCount(itemCount)}',
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
              label: 'Place order · ${Money.format(total)}',
              isLoading: isPlacing,
              onPressed: _placeOrder,
            ),
          ],
        ),
      ),
    );
  }
}
