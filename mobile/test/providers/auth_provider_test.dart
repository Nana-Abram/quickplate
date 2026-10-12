import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quickplate/core/errors/app_exception.dart';
import 'package:quickplate/data/models/app_user.dart';
import 'package:quickplate/providers/auth_provider.dart';
import 'package:quickplate/providers/view_state.dart';

import '../helpers/mocks.dart';

void main() {
  const user = AppUser(uid: 'u1', email: 'ama@example.com');
  const email = 'ama@example.com';
  const password = 'secret123';

  late MockAuthRepository repository;
  late StreamController<AppUser?> userChanges;

  setUp(() {
    repository = MockAuthRepository();
    userChanges = StreamController<AppUser?>();
    when(() => repository.userChanges()).thenAnswer((_) => userChanges.stream);
  });

  tearDown(() => userChanges.close());

  group('session', () {
    test('starts unknown until Firebase reports the session', () {
      final provider = AuthProvider(repository);

      expect(provider.status, AuthStatus.unknown);
      expect(provider.user, isNull);
    });

    test('follows sign-in and sign-out', () async {
      final provider = AuthProvider(repository);
      final statuses = <AuthStatus>[];
      provider.addListener(() => statuses.add(provider.status));

      userChanges
        ..add(null)
        ..add(user)
        ..add(null);
      await pumpEventQueue();

      expect(statuses, [
        AuthStatus.signedOut,
        AuthStatus.signedIn,
        AuthStatus.signedOut,
      ]);
    });

    test('picks up a display name set after registration', () async {
      final provider = AuthProvider(repository);

      userChanges
        ..add(user)
        ..add(user.copyWith(displayName: 'Ama'));
      await pumpEventQueue();

      expect(provider.user?.displayName, 'Ama');
    });

    test('does not notify for a repeated identical state', () async {
      final provider = AuthProvider(repository);
      var notifications = 0;
      provider.addListener(() => notifications++);

      userChanges
        ..add(user)
        ..add(user);
      await pumpEventQueue();

      expect(notifications, 1);
    });
  });

  group('signIn', () {
    test('success goes loading then success', () async {
      when(() => repository.signIn(email: email, password: password))
          .thenAnswer((_) async {});
      final provider = AuthProvider(repository);
      final states = <ViewState>[];
      provider.addListener(() => states.add(provider.actionState));

      final ok = await provider.signIn(email: email, password: password);

      expect(ok, isTrue);
      expect(states, [ViewState.loading, ViewState.success]);
      expect(provider.errorMessage, isNull);
    });

    test('failure exposes the user-facing message', () async {
      when(() => repository.signIn(email: email, password: password))
          .thenThrow(const AuthException('Incorrect email or password.'));
      final provider = AuthProvider(repository);

      final ok = await provider.signIn(email: email, password: password);

      expect(ok, isFalse);
      expect(provider.actionState, ViewState.error);
      expect(provider.errorMessage, 'Incorrect email or password.');
    });

    test('ignores a second call while one is running', () async {
      final pending = Completer<void>();
      when(() => repository.signIn(email: email, password: password))
          .thenAnswer((_) => pending.future);
      final provider = AuthProvider(repository);

      final first = provider.signIn(email: email, password: password);
      final second = await provider.signIn(email: email, password: password);
      pending.complete();
      await first;

      expect(second, isFalse);
      verify(() => repository.signIn(email: email, password: password))
          .called(1);
    });

    test('a new attempt clears the previous error', () async {
      var attempt = 0;
      when(() => repository.signIn(email: email, password: password))
          .thenAnswer((_) async {
            if (attempt++ == 0) throw const NetworkException();
          });
      final provider = AuthProvider(repository);

      await provider.signIn(email: email, password: password);
      expect(provider.errorMessage, isNotNull);
      await provider.signIn(email: email, password: password);

      expect(provider.errorMessage, isNull);
      expect(provider.actionState, ViewState.success);
    });
  });

  test('register passes name, email and password through', () async {
    when(
      () => repository.register(name: 'Ama', email: email, password: password),
    ).thenAnswer((_) async {});
    final provider = AuthProvider(repository);

    final ok = await provider.register(
      name: 'Ama',
      email: email,
      password: password,
    );

    expect(ok, isTrue);
    verify(
      () => repository.register(name: 'Ama', email: email, password: password),
    ).called(1);
  });

  test('sendPasswordReset reports failures', () async {
    when(() => repository.sendPasswordReset(email))
        .thenThrow(const NetworkException());
    final provider = AuthProvider(repository);

    final ok = await provider.sendPasswordReset(email);

    expect(ok, isFalse);
    expect(provider.errorMessage, const NetworkException().message);
  });

  test('resetActionState clears a previous error', () async {
    when(() => repository.signOut()).thenThrow(const UnknownException());
    final provider = AuthProvider(repository);
    await provider.signOut();

    provider.resetActionState();

    expect(provider.actionState, ViewState.idle);
    expect(provider.errorMessage, isNull);
  });
}
