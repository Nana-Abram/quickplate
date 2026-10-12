import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quickplate/data/models/app_user.dart';
import 'package:quickplate/data/repositories/auth_repository.dart';
import 'package:quickplate/providers/auth_provider.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  const user = AppUser(uid: 'u1', email: 'ama@example.com');

  late MockAuthRepository repository;
  late StreamController<AppUser?> authChanges;

  setUp(() {
    repository = MockAuthRepository();
    authChanges = StreamController<AppUser?>();
    when(() => repository.authStateChanges())
        .thenAnswer((_) => authChanges.stream);
  });

  tearDown(() => authChanges.close());

  group('AuthProvider session', () {
    test('starts unknown until Firebase reports the session', () {
      final provider = AuthProvider(repository);

      expect(provider.status, AuthStatus.unknown);
      expect(provider.user, isNull);
    });

    test('follows sign-in and sign-out', () async {
      final provider = AuthProvider(repository);
      final statuses = <AuthStatus>[];
      provider.addListener(() => statuses.add(provider.status));

      authChanges
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

    test('exposes the signed-in user', () async {
      final provider = AuthProvider(repository);

      authChanges.add(user);
      await pumpEventQueue();

      expect(provider.status, AuthStatus.signedIn);
      expect(provider.user, user);
    });

    test('does not notify for a repeated identical state', () async {
      final provider = AuthProvider(repository);
      var notifications = 0;
      provider.addListener(() => notifications++);

      authChanges
        ..add(user)
        ..add(user);
      await pumpEventQueue();

      expect(notifications, 1);
    });

    test('signOut delegates to the repository', () async {
      when(() => repository.signOut()).thenAnswer((_) async {});
      final provider = AuthProvider(repository);

      await provider.signOut();

      verify(() => repository.signOut()).called(1);
    });
  });
}
