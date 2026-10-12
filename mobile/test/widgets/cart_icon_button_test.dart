import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:quickplate/providers/cart_provider.dart';
import 'package:quickplate/widgets/cart_icon_button.dart';

import '../helpers/fixtures.dart';

void main() {
  testWidgets('announces the item count, not just the badge number', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final cart = CartProvider()
      ..addItem(restaurant: restaurant(), item: menuItem(), quantity: 2);

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: cart,
        child: const MaterialApp(home: Scaffold(body: CartIconButton())),
      ),
    );

    expect(find.byTooltip('Cart, 2 items'), findsOneWidget);
    expect(find.bySemanticsLabel('2'), findsNothing);
    semantics.dispose();
  });
}
