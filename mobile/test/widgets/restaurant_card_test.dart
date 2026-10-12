import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickplate/core/theme/app_theme.dart';
import 'package:quickplate/widgets/restaurant_card.dart';

import '../helpers/fixtures.dart';

void main() {
  Future<void> pumpCard(WidgetTester tester, RestaurantCard card) {
    return tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(body: SingleChildScrollView(child: card)),
      ),
    );
  }

  testWidgets('shows name, categories, rating, ETA and delivery fee', (
    tester,
  ) async {
    await pumpCard(tester, RestaurantCard(restaurant: restaurant()));

    expect(find.text("Adwoa's Kitchen"), findsOneWidget);
    expect(find.text('Local'), findsOneWidget);
    expect(find.text('4.7'), findsOneWidget);
    expect(find.text('35 min'), findsOneWidget);
    expect(find.text('GH₵12.00'), findsOneWidget);
    expect(find.text('Closed'), findsNothing);
  });

  testWidgets('marks a closed restaurant and a free delivery fee', (
    tester,
  ) async {
    await pumpCard(
      tester,
      RestaurantCard(
        restaurant: restaurant(isOpen: false, deliveryFeePesewas: 0),
      ),
    );

    expect(find.text('Closed'), findsOneWidget);
    expect(find.text('Free'), findsOneWidget);
  });

  testWidgets('calls onTap', (tester) async {
    var taps = 0;
    await pumpCard(
      tester,
      RestaurantCard(restaurant: restaurant(), onTap: () => taps++),
    );

    await tester.tap(find.byType(RestaurantCard));

    expect(taps, 1);
  });

  testWidgets('describes its facts to screen readers', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpCard(tester, RestaurantCard(restaurant: restaurant()));

    // The tappable card merges its children into one announcement.
    final card = find.bySemanticsLabel(RegExp("Adwoa's Kitchen"));
    final label = tester.getSemantics(card).label;

    expect(label, contains('Rated 4.7'));
    expect(label, contains('About 35 minutes'));
    expect(label, contains('Delivery GH₵12.00'));
    semantics.dispose();
  });
}
