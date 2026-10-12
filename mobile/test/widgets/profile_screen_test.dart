import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:quickplate/core/theme/app_theme.dart';
import 'package:quickplate/data/models/address.dart';
import 'package:quickplate/data/models/app_user.dart';
import 'package:quickplate/providers/address_book_provider.dart';
import 'package:quickplate/providers/auth_provider.dart';
import 'package:quickplate/providers/theme_provider.dart';
import 'package:quickplate/screens/profile/profile_screen.dart';

import '../helpers/mocks.dart';

void main() {
  const user = AppUser(
    uid: 'u1',
    email: 'ama@example.com',
    displayName: 'Ama Mensah',
  );
  const home = Address(
    label: 'Home',
    line1: '12 Prempeh II St',
    latitude: 6.69,
    longitude: -1.62,
  );

  late MockAuthRepository auth;
  late MockAddressBookRepository book;
  late StreamController<AppUser?> userChanges;
  late ThemeProvider theme;

  setUp(() {
    auth = MockAuthRepository();
    book = MockAddressBookRepository();
    userChanges = StreamController<AppUser?>();
    theme = ThemeProvider();
    when(() => auth.userChanges()).thenAnswer((_) => userChanges.stream);
    when(() => book.save(any(), any())).thenAnswer((_) async {});
  });

  tearDown(() => unawaited(userChanges.close()));

  Future<void> pumpProfile(WidgetTester tester, List<Address> saved) async {
    when(() => book.load('u1')).thenAnswer((_) async => saved);
    final addressBook = AddressBookProvider(book)..onAuthChanged(user);
    userChanges.add(user);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider(auth)),
          ChangeNotifierProvider.value(value: addressBook),
          ChangeNotifierProvider.value(value: theme),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const ProfileScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows the user, saved addresses and sign out', (tester) async {
    await pumpProfile(tester, [home]);

    expect(find.text('Ama Mensah'), findsOneWidget);
    expect(find.text('ama@example.com'), findsOneWidget);
    expect(find.text('12 Prempeh II St'), findsOneWidget);
    expect(find.text('Sign out'), findsOneWidget);
  });

  testWidgets('the theme selector changes the theme', (tester) async {
    await pumpProfile(tester, []);

    await tester.tap(find.text('Dark'));
    await tester.pump();

    expect(theme.themeMode, ThemeMode.dark);
  });

  testWidgets('removing an address updates the list', (tester) async {
    await pumpProfile(tester, [home]);

    await tester.tap(find.byTooltip('Remove Home'));
    await tester.pumpAndSettle();

    expect(find.text('12 Prempeh II St'), findsNothing);
    expect(find.textContaining('No saved addresses yet'), findsOneWidget);
    verify(() => book.save('u1', [])).called(1);
  });
}
