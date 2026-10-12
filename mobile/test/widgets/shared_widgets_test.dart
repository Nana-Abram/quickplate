import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickplate/core/theme/app_theme.dart';
import 'package:quickplate/widgets/app_button.dart';
import 'package:quickplate/widgets/app_text_field.dart';
import 'package:quickplate/widgets/empty_view.dart';
import 'package:quickplate/widgets/error_view.dart';

Widget wrap(Widget child) => MaterialApp(
  theme: AppTheme.light(),
  home: Scaffold(body: child),
);

void main() {
  group('AppButton', () {
    testWidgets('calls onPressed when tapped', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        wrap(AppButton(label: 'Sign in', onPressed: () => taps++)),
      );

      await tester.tap(find.text('Sign in'));

      expect(taps, 1);
    });

    testWidgets('shows a spinner and ignores taps while loading', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(
        wrap(
          AppButton(label: 'Sign in', isLoading: true, onPressed: () => taps++),
        ),
      );

      await tester.tap(find.byType(FilledButton));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Sign in'), findsNothing);
      expect(taps, 0);
    });
  });

  group('AppTextField', () {
    testWidgets('password visibility can be toggled', (tester) async {
      await tester.pumpWidget(
        wrap(const AppTextField(label: 'Password', isPassword: true)),
      );
      bool obscured() =>
          tester.widget<EditableText>(find.byType(EditableText)).obscureText;

      expect(obscured(), isTrue);
      await tester.tap(find.byTooltip('Show password'));
      await tester.pump();
      expect(obscured(), isFalse);
    });
  });

  group('ErrorView', () {
    testWidgets('shows the message and retries', (tester) async {
      var retries = 0;
      await tester.pumpWidget(
        wrap(ErrorView(message: 'No internet.', onRetry: () => retries++)),
      );

      await tester.tap(find.text('Try again'));

      expect(find.text('No internet.'), findsOneWidget);
      expect(retries, 1);
    });

    testWidgets('hides the retry button without a callback', (tester) async {
      await tester.pumpWidget(wrap(const ErrorView(message: 'Oops')));

      expect(find.text('Try again'), findsNothing);
    });
  });

  group('EmptyView', () {
    testWidgets('shows title, message and action', (tester) async {
      var actions = 0;
      await tester.pumpWidget(
        wrap(
          EmptyView(
            title: 'No orders yet',
            message: 'Your orders will show up here.',
            actionLabel: 'Browse restaurants',
            onAction: () => actions++,
          ),
        ),
      );

      await tester.tap(find.text('Browse restaurants'));

      expect(find.text('No orders yet'), findsOneWidget);
      expect(find.text('Your orders will show up here.'), findsOneWidget);
      expect(actions, 1);
    });
  });
}
