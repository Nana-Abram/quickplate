import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:quickplate/core/theme/app_theme.dart';
import 'package:quickplate/providers/cart_provider.dart';
import 'package:quickplate/screens/cart/cart_screen.dart';

import '../helpers/fixtures.dart';

void main() {
  Future<CartProvider> pumpCart(
    WidgetTester tester, {
    void Function(CartProvider cart)? fill,
  }) async {
    final cart = CartProvider();
    fill?.call(cart);
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: cart,
        child: MaterialApp(theme: AppTheme.light(), home: const CartScreen()),
      ),
    );
    return cart;
  }

  testWidgets('shows the empty state', (tester) async {
    await pumpCart(tester);

    expect(find.text('Your cart is empty'), findsOneWidget);
    expect(find.text('Browse restaurants'), findsOneWidget);
    expect(find.text('Clear cart'), findsNothing);
  });

  testWidgets('lists lines and totals in cedis', (tester) async {
    await pumpCart(
      tester,
      fill: (cart) => cart.addItem(
        restaurant: restaurant(deliveryFeePesewas: 1200),
        item: menuItem(),
        quantity: 2,
        notes: 'extra shito',
      ),
    );

    expect(find.text('Jollof Rice'), findsOneWidget);
    expect(find.text('Note: extra shito'), findsOneWidget);
    expect(find.text('GH₵90.00'), findsNWidgets(2)); // line and subtotal
    expect(find.text('GH₵12.00'), findsOneWidget);
    expect(find.text('GH₵102.00'), findsOneWidget);
  });

  testWidgets('steppers change the quantity and totals', (tester) async {
    final cart = await pumpCart(
      tester,
      fill: (cart) => cart.addItem(restaurant: restaurant(), item: menuItem()),
    );

    await tester.tap(find.byTooltip('Add one Jollof Rice'));
    await tester.pump();

    expect(cart.itemCount, 2);
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('clear cart asks first', (tester) async {
    final cart = await pumpCart(
      tester,
      fill: (cart) => cart.addItem(restaurant: restaurant(), item: menuItem()),
    );

    await tester.tap(find.widgetWithText(TextButton, 'Clear cart'));
    await tester.pumpAndSettle();
    expect(find.text('Clear your cart?'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Clear cart'));
    await tester.pumpAndSettle();

    expect(cart.isEmpty, isTrue);
    expect(find.text('Your cart is empty'), findsOneWidget);
  });

  testWidgets('swiping a line removes it', (tester) async {
    final cart = await pumpCart(
      tester,
      fill: (cart) => cart.addItem(restaurant: restaurant(), item: menuItem()),
    );

    await tester.drag(find.text('Jollof Rice'), const Offset(-600, 0));
    await tester.pumpAndSettle();

    expect(cart.isEmpty, isTrue);
  });
}
