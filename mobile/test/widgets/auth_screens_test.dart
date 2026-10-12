import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:quickplate/core/errors/app_exception.dart';
import 'package:quickplate/core/theme/app_theme.dart';
import 'package:quickplate/data/models/app_user.dart';
import 'package:quickplate/providers/auth_provider.dart';
import 'package:quickplate/screens/auth/forgot_password_screen.dart';
import 'package:quickplate/screens/auth/login_screen.dart';
import 'package:quickplate/screens/auth/register_screen.dart';

import '../helpers/mocks.dart';

void main() {
  late MockAuthRepository repository;
  late StreamController<AppUser?> userChanges;

  setUp(() {
    repository = MockAuthRepository();
    userChanges = StreamController<AppUser?>();
    when(() => repository.userChanges()).thenAnswer((_) => userChanges.stream);
  });

  tearDown(() => userChanges.close());

  Future<void> pumpScreen(WidgetTester tester, Widget screen) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AuthProvider(repository),
        child: MaterialApp(theme: AppTheme.light(), home: screen),
      ),
    );
    await tester.pump();
  }

  Finder field(String label) => find.widgetWithText(TextFormField, label);

  group('LoginScreen', () {
    testWidgets('validates before calling the repository', (tester) async {
      await pumpScreen(tester, const LoginScreen());

      final signIn = find.widgetWithText(FilledButton, 'Sign in');
      await tester.ensureVisible(signIn);
      await tester.tap(signIn);
      await tester.pump();

      expect(find.text('Enter your email address.'), findsOneWidget);
      expect(find.text('Enter your password.'), findsOneWidget);
      verifyNever(
        () => repository.signIn(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      );
    });

    testWidgets('shows the friendly error when sign-in fails', (tester) async {
      when(() => repository.signIn(email: 'ama@example.com', password: 'wrong'))
          .thenThrow(const AuthException('Incorrect email or password.'));
      await pumpScreen(tester, const LoginScreen());

      await tester.enterText(field('Email'), 'ama@example.com');
      await tester.enterText(field('Password'), 'wrong');
      final signIn = find.widgetWithText(FilledButton, 'Sign in');
      await tester.ensureVisible(signIn);
      await tester.tap(signIn);
      await tester.pump();

      expect(find.text('Incorrect email or password.'), findsOneWidget);
    });
  });

  group('RegisterScreen', () {
    testWidgets('requires matching passwords of 8+ characters', (tester) async {
      await pumpScreen(tester, const RegisterScreen());

      await tester.enterText(field('Name'), 'Ama');
      await tester.enterText(field('Email'), 'ama@example.com');
      await tester.enterText(field('Password'), 'short');
      await tester.enterText(field('Confirm password'), 'different');
      await tester.ensureVisible(find.text('Create account'));
      await tester.tap(find.text('Create account'));
      await tester.pump();

      expect(find.text('Use at least 8 characters.'), findsOneWidget);
      expect(find.text('Passwords do not match.'), findsOneWidget);
      verifyNever(
        () => repository.register(
          name: any(named: 'name'),
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      );
    });
  });

  group('ForgotPasswordScreen', () {
    testWidgets('confirms without revealing whether the account exists', (
      tester,
    ) async {
      when(() => repository.sendPasswordReset('ama@example.com'))
          .thenAnswer((_) async {});
      await pumpScreen(tester, const ForgotPasswordScreen());

      await tester.enterText(field('Email'), 'ama@example.com');
      await tester.tap(find.text('Send reset link'));
      await tester.pump();

      expect(find.text('Check your inbox'), findsOneWidget);
      expect(find.textContaining('If an account exists'), findsOneWidget);
    });
  });
}
