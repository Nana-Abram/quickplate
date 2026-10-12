import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../data/models/address.dart';
import '../../providers/address_picker_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/menu_provider.dart';
import '../../providers/order_tracking_provider.dart';
import '../../screens/auth/forgot_password_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/register_screen.dart';
import '../../screens/cart/cart_screen.dart';
import '../../screens/checkout/address_picker_screen.dart';
import '../../screens/checkout/checkout_screen.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/orders/orders_screen.dart';
import '../../screens/profile/profile_screen.dart';
import '../../screens/restaurant/restaurant_screen.dart';
import '../../screens/splash/splash_screen.dart';
import '../../screens/tracking/order_tracking_screen.dart';
import '../constants/map_config.dart';
import '../constants/routes.dart';

/// Decides where a user may go given their session. Kept free of Flutter so
/// it can be unit tested directly.
///
/// While the session is unknown everything waits on the splash, which keeps
/// the original location in `from` so a deep link survives app start.
String? authRedirect({required AuthStatus status, required Uri location}) {
  final path = location.path;
  final onSplash = path == Routes.splash;
  final onAuthRoute = Routes.authRoutes.contains(path);

  switch (status) {
    case AuthStatus.unknown:
      if (onSplash) return null;
      return Uri(
        path: Routes.splash,
        queryParameters: {'from': location.toString()},
      ).toString();
    case AuthStatus.signedOut:
      return onAuthRoute ? null : Routes.login;
    case AuthStatus.signedIn:
      if (onSplash) return location.queryParameters['from'] ?? Routes.home;
      return onAuthRoute ? Routes.home : null;
  }
}

GoRouter createRouter(AuthProvider authProvider) {
  return GoRouter(
    initialLocation: Routes.splash,
    refreshListenable: authProvider,
    redirect: (_, state) =>
        authRedirect(status: authProvider.status, location: state.uri),
    routes: [
      GoRoute(path: Routes.splash, builder: (_, _) => const SplashScreen()),
      GoRoute(path: Routes.login, builder: (_, _) => const LoginScreen()),
      GoRoute(path: Routes.register, builder: (_, _) => const RegisterScreen()),
      GoRoute(
        path: Routes.forgotPassword,
        builder: (_, _) => const ForgotPasswordScreen(),
      ),
      GoRoute(path: Routes.home, builder: (_, _) => const HomeScreen()),
      GoRoute(path: Routes.profile, builder: (_, _) => const ProfileScreen()),
      GoRoute(path: Routes.cart, builder: (_, _) => const CartScreen()),
      GoRoute(path: Routes.checkout, builder: (_, _) => const CheckoutScreen()),
      GoRoute(
        path: Routes.addressPicker,
        builder: (context, state) {
          final initial = state.extra as Address?;
          return ChangeNotifierProvider(
            create: (c) => AddressPickerProvider(
              c.read(),
              initialCenter: _pickerStart(c, initial),
            ),
            child: AddressPickerScreen(initialAddress: initial),
          );
        },
      ),
      GoRoute(path: Routes.orders, builder: (_, _) => const OrdersScreen()),
      GoRoute(
        path: Routes.orderDetail,
        // Screen-scoped: disposing it cancels the Firestore listener.
        builder: (_, state) => ChangeNotifierProvider(
          create: (context) => OrderTrackingProvider(
            context.read(),
            context.read(),
            state.pathParameters['id']!,
          )..load(),
          child: const OrderTrackingScreen(),
        ),
      ),
      GoRoute(
        path: Routes.restaurant,
        // Screen-scoped: the menu provider is disposed with the screen.
        builder: (_, state) => ChangeNotifierProvider(
          create: (context) =>
              MenuProvider(context.read(), state.pathParameters['id']!)..load(),
          child: const RestaurantScreen(),
        ),
      ),
    ],
  );
}

/// Where the address pin starts: the last chosen address, else the
/// restaurant (deliveries are local), else the city centre.
LatLng _pickerStart(BuildContext context, Address? initial) {
  if (initial != null) return LatLng(initial.latitude, initial.longitude);
  final restaurant = context.read<CartProvider>().restaurant;
  if (restaurant != null) {
    return LatLng(restaurant.latitude, restaurant.longitude);
  }
  return MapConfig.defaultCenter;
}
