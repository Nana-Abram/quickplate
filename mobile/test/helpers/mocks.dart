import 'package:mocktail/mocktail.dart';
import 'package:quickplate/data/repositories/auth_repository.dart';
import 'package:quickplate/data/repositories/restaurant_repository.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockRestaurantRepository extends Mock implements RestaurantRepository {}
