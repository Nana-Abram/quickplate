import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quickplate/core/errors/app_exception.dart';
import 'package:quickplate/data/models/app_user.dart';
import 'package:quickplate/data/services/notification_service.dart';
import 'package:quickplate/providers/notification_provider.dart';

import '../helpers/mocks.dart';

void main() {
  const ama = AppUser(uid: 'ama', email: 'ama@example.com');
  const kofi = AppUser(uid: 'kofi', email: 'kofi@example.com');

  late MockNotificationRepository repository;
  late StreamController<String> tokenRefresh;

  setUp(() {
    repository = MockNotificationRepository();
    tokenRefresh = StreamController<String>.broadcast();
    when(() => repository.onTokenRefresh)
        .thenAnswer((_) => tokenRefresh.stream);
    when(() => repository.registerDevice()).thenAnswer((_) async => true);
    when(() => repository.uploadToken(any())).thenAnswer((_) async {});
    when(() => repository.unregisterDevice()).thenAnswer((_) async {});
  });

  tearDown(() => tokenRefresh.close());

  test('registers the device once per signed-in user', () async {
    final provider = NotificationProvider(repository)
      ..onAuthChanged(ama)
      ..onAuthChanged(ama);
    await pumpEventQueue();

    verify(() => repository.registerDevice()).called(1);

    provider.onAuthChanged(kofi);
    await pumpEventQueue();
    verify(() => repository.registerDevice()).called(1);
  });

  test('uploads refreshed tokens while signed in', () async {
    NotificationProvider(repository).onAuthChanged(ama);
    await pumpEventQueue();

    tokenRefresh.add('new-token');
    await pumpEventQueue();

    verify(() => repository.uploadToken('new-token')).called(1);
  });

  test(
    'records a declined permission and does not listen for tokens',
    () async {
      when(() => repository.registerDevice()).thenAnswer((_) async => false);
      final provider = NotificationProvider(repository)..onAuthChanged(ama);
      await pumpEventQueue();

      expect(provider.permissionDenied, isTrue);
      tokenRefresh.add('ignored');
      await pumpEventQueue();
      verifyNever(() => repository.uploadToken(any()));
    },
  );

  test('signing out deletes the token and stops uploads', () async {
    final provider = NotificationProvider(repository)..onAuthChanged(ama);
    await pumpEventQueue();

    provider.onAuthChanged(null);
    await pumpEventQueue();
    tokenRefresh.add('after-sign-out');
    await pumpEventQueue();

    verify(() => repository.unregisterDevice()).called(1);
    verifyNever(() => repository.uploadToken(any()));
  });

  test('a failed registration does not throw', () async {
    when(() => repository.registerDevice()).thenThrow(const NetworkException());

    NotificationProvider(repository).onAuthChanged(ama);

    await expectLater(pumpEventQueue(), completes);
  });

  test('maps an FCM message to a PushMessage with the order id', () {
    const remote = RemoteMessage(
      notification: RemoteNotification(
        title: 'On the way',
        body: 'Your rider is on the way.',
      ),
      data: {'orderId': 'o-42', 'status': 'on_the_way'},
    );

    final message = NotificationService.toPushMessage(remote);

    expect(message.title, 'On the way');
    expect(message.body, 'Your rider is on the way.');
    expect(message.orderId, 'o-42');
  });
}
