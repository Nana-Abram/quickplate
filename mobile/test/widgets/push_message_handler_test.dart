import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:quickplate/core/constants/routes.dart';
import 'package:quickplate/data/models/push_message.dart';
import 'package:quickplate/providers/notification_provider.dart';
import 'package:quickplate/widgets/push_message_handler.dart';

import '../helpers/mocks.dart';

void main() {
  late MockNotificationRepository repository;
  late StreamController<PushMessage> foreground;
  late StreamController<PushMessage> opened;

  setUp(() {
    repository = MockNotificationRepository();
    foreground = StreamController<PushMessage>.broadcast();
    opened = StreamController<PushMessage>.broadcast();
    when(() => repository.onForegroundMessage)
        .thenAnswer((_) => foreground.stream);
    when(() => repository.onMessageOpenedApp).thenAnswer((_) => opened.stream);
    when(() => repository.getInitialMessage()).thenAnswer((_) async => null);
  });

  tearDown(() {
    unawaited(foreground.close());
    unawaited(opened.close());
  });

  Future<void> pumpApp(WidgetTester tester) async {
    final messengerKey = GlobalKey<ScaffoldMessengerState>();
    final router = GoRouter(
      initialLocation: Routes.home,
      routes: [
        GoRoute(
          path: Routes.home,
          builder: (_, _) => const Scaffold(body: Text('home')),
        ),
        GoRoute(
          path: Routes.orderDetail,
          builder: (_, state) =>
              Scaffold(body: Text('order ${state.pathParameters['id']}')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => NotificationProvider(repository),
        child: PushMessageHandler(
          router: router,
          messengerKey: messengerKey,
          child: MaterialApp.router(
            scaffoldMessengerKey: messengerKey,
            routerConfig: router,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('a push while the app is open shows a banner that opens '
      'the order', (tester) async {
    await pumpApp(tester);

    foreground.add(
      const PushMessage(
        title: 'On the way',
        body: 'Your rider is on the way.',
        orderId: 'o-42',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('On the way: Your rider is on the way.'), findsOneWidget);

    await tester.tap(find.text('View'));
    await tester.pumpAndSettle();
    expect(find.text('order o-42'), findsOneWidget);
  });

  testWidgets('tapping a notification opens the order', (tester) async {
    await pumpApp(tester);

    opened.add(const PushMessage(orderId: 'o-7'));
    await tester.pumpAndSettle();

    expect(find.text('order o-7'), findsOneWidget);
  });

  testWidgets('a notification that launched the app opens its order', (
    tester,
  ) async {
    when(() => repository.getInitialMessage())
        .thenAnswer((_) async => const PushMessage(orderId: 'o-1'));

    await pumpApp(tester);

    expect(find.text('order o-1'), findsOneWidget);
  });

  testWidgets('the same tap reported twice opens the order once', (
    tester,
  ) async {
    const tap = PushMessage(messageId: 'm-1', orderId: 'o-9');
    when(() => repository.getInitialMessage()).thenAnswer((_) async => tap);
    await pumpApp(tester);

    opened.add(tap);
    await tester.pumpAndSettle();

    expect(find.text('order o-9'), findsOneWidget);
    // Only one order page was pushed: one Back returns home.
    GoRouter.of(tester.element(find.text('order o-9'))).pop();
    await tester.pumpAndSettle();
    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('no banner for the order already on screen', (tester) async {
    when(() => repository.getInitialMessage())
        .thenAnswer((_) async => const PushMessage(orderId: 'o-5'));
    await pumpApp(tester);
    expect(find.text('order o-5'), findsOneWidget);

    foreground.add(
      const PushMessage(title: 'Preparing', body: 'Cooking.', orderId: 'o-5'),
    );
    await tester.pumpAndSettle();
    expect(find.text('Preparing: Cooking.'), findsNothing);

    foreground.add(
      const PushMessage(title: 'Preparing', body: 'Cooking.', orderId: 'o-6'),
    );
    await tester.pumpAndSettle();
    expect(find.text('Preparing: Cooking.'), findsOneWidget);
  });
}
