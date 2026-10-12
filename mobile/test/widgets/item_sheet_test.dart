import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:quickplate/core/constants/routes.dart';
import 'package:quickplate/core/theme/app_theme.dart';
import 'package:quickplate/data/models/menu_item.dart';
import 'package:quickplate/data/models/restaurant.dart';
import 'package:quickplate/providers/cart_provider.dart';
import 'package:quickplate/screens/restaurant/widgets/item_sheet.dart';

import '../helpers/fixtures.dart';

void main() {
  late CartProvider cart;

  setUp(() => cart = CartProvider());

  Future<void> openSheet(
    WidgetTester tester, {
    required Restaurant restaurant,
    required MenuItem item,
  }) async {
    // A phone-sized screen, so the whole sheet fits.
    tester.view
      ..physicalSize = const Size(1080, 2400)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, _) => Scaffold(
            body: TextButton(
              onPressed: () =>
                  showItemSheet(context, restaurant: restaurant, item: item),
              child: const Text('open'),
            ),
          ),
        ),
        GoRoute(
          path: Routes.cart,
          builder: (_, _) => const Scaffold(body: Text('cart screen')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: cart,
        child: MaterialApp.router(
          theme: AppTheme.light(),
          routerConfig: router,
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('adds the chosen quantity and notes', (tester) async {
    await openSheet(tester, restaurant: restaurant(), item: menuItem());

    await tester.tap(find.byTooltip('Add one Jollof Rice'));
    await tester.pump();
    await tester.enterText(find.byType(TextFormField), 'no pepper');
    expect(find.text('Add to cart · GH₵90.00'), findsOneWidget);

    await tester.tap(find.text('Add to cart · GH₵90.00'));
    await tester.pumpAndSettle();

    expect(cart.items.single.quantity, 2);
    expect(cart.items.single.notes, 'no pepper');
    expect(find.text('Added Jollof Rice to your cart.'), findsOneWidget);

    await tester.tap(find.text('View cart'));
    await tester.pumpAndSettle();
    expect(find.text('cart screen'), findsOneWidget);
  });

  testWidgets('asks before replacing another restaurant\'s cart', (
    tester,
  ) async {
    cart.addItem(
      restaurant: restaurant(id: 'other', name: 'Osu Chop Bar'),
      item: menuItem(),
    );
    await openSheet(
      tester,
      restaurant: restaurant(),
      item: menuItem(id: 'waakye'),
    );

    await tester.tap(find.textContaining('Add to cart'));
    await tester.pumpAndSettle();
    expect(find.text('Start a new cart?'), findsOneWidget);
    expect(find.textContaining('Osu Chop Bar'), findsOneWidget);

    await tester.tap(find.text('Keep cart'));
    await tester.pumpAndSettle();
    expect(cart.restaurant?.id, 'other');

    await tester.tap(find.textContaining('Add to cart'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start new cart'));
    await tester.pumpAndSettle();

    expect(cart.restaurant?.id, 'adwoas-kitchen');
    expect(cart.items.single.menuItemId, 'waakye');
  });

  testWidgets('cannot add from a closed restaurant', (tester) async {
    await openSheet(
      tester,
      restaurant: restaurant(isOpen: false),
      item: menuItem(),
    );

    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Restaurant is closed'),
    );
    expect(button.onPressed, isNull);
  });
}
