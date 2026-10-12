import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:quickplate/core/theme/app_theme.dart';
import 'package:quickplate/data/models/order.dart';
import 'package:quickplate/data/models/order_status.dart';
import 'package:quickplate/widgets/order_status_chip.dart';
import 'package:quickplate/widgets/status_timeline.dart';

void main() {
  final at = DateTime(2026, 10, 12, 10, 5);
  // intl separates AM/PM with a narrow no-break space, so build it the same way.
  final time = DateFormat.jm().format(at);

  Future<void> pump(WidgetTester tester, Widget child) {
    return tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    );
  }

  List<String> stepLabels(WidgetTester tester) => [
    for (final status in OrderStatus.values)
      if (find
          .bySemanticsLabel(RegExp('^${status.label},'))
          .evaluate()
          .isNotEmpty)
        tester
            .getSemantics(find.bySemanticsLabel(RegExp('^${status.label},')))
            .label,
  ];

  testWidgets('marks done, current and upcoming steps', (tester) async {
    final semantics = tester.ensureSemantics();
    await pump(
      tester,
      StatusTimeline(
        status: OrderStatus.preparing,
        history: [
          StatusChange(status: OrderStatus.placed, at: at),
          StatusChange(status: OrderStatus.accepted, at: at),
          StatusChange(status: OrderStatus.preparing, at: at),
        ],
      ),
    );

    expect(stepLabels(tester), [
      'Order placed, done at $time',
      'Accepted, done at $time',
      'Preparing, in progress',
      'On the way, not yet',
      'Delivered, not yet',
    ]);
    semantics.dispose();
  });

  testWidgets('a delivered order has every step done', (tester) async {
    final semantics = tester.ensureSemantics();
    await pump(
      tester,
      const StatusTimeline(status: OrderStatus.delivered, history: []),
    );

    expect(stepLabels(tester).last, 'Delivered, done');
    semantics.dispose();
  });

  testWidgets('a cancelled order shows only placed and cancelled', (
    tester,
  ) async {
    await pump(
      tester,
      const StatusTimeline(status: OrderStatus.cancelled, history: []),
    );

    expect(find.text('Order placed'), findsOneWidget);
    expect(find.text('Cancelled'), findsOneWidget);
    expect(find.text('Preparing'), findsNothing);
  });

  testWidgets('status chip shows the label', (tester) async {
    await pump(tester, const OrderStatusChip(status: OrderStatus.onTheWay));

    expect(find.text('On the way'), findsOneWidget);
  });
}
