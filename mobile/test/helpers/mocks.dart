import 'package:mocktail/mocktail.dart';
import 'package:quickplate/data/repositories/auth_repository.dart';
import 'package:quickplate/data/repositories/notification_repository.dart';
import 'package:quickplate/data/repositories/order_repository.dart';
import 'package:quickplate/data/repositories/restaurant_repository.dart';
import 'package:quickplate/data/services/location_service.dart';
import 'package:quickplate/data/services/restaurant_api_service.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockRestaurantRepository extends Mock implements RestaurantRepository {}

class MockLocationService extends Mock implements LocationService {}

class MockOrderRepository extends Mock implements OrderRepository {}

class MockNotificationRepository extends Mock
    implements NotificationRepository {}

class MockRestaurantApiService extends Mock implements RestaurantApiService {}
