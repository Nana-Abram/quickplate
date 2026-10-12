import 'package:flutter/material.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quickplate/data/repositories/address_book_repository.dart';
import 'package:quickplate/data/repositories/auth_repository.dart';
import 'package:quickplate/data/repositories/notification_repository.dart';
import 'package:quickplate/data/repositories/order_repository.dart';
import 'package:quickplate/data/repositories/restaurant_repository.dart';
import 'package:quickplate/data/repositories/settings_repository.dart';
import 'package:quickplate/data/services/location_service.dart';
import 'package:quickplate/data/services/restaurant_api_service.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockRestaurantRepository extends Mock implements RestaurantRepository {}

class MockLocationService extends Mock implements LocationService {}

class MockOrderRepository extends Mock implements OrderRepository {}

class MockNotificationRepository extends Mock
    implements NotificationRepository {}

class MockRestaurantApiService extends Mock implements RestaurantApiService {}

class MockAddressBookRepository extends Mock implements AddressBookRepository {}

class MockSettingsRepository extends Mock implements SettingsRepository {}

/// Quiet stand-in for screens that only need a theme provider.
class FakeSettingsRepository extends Fake implements SettingsRepository {
  @override
  Future<ThemeMode> loadThemeMode() async => ThemeMode.system;

  @override
  Future<void> saveThemeMode(ThemeMode mode) async {}
}
