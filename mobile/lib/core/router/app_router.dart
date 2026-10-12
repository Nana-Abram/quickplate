import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/menu_provider.dart';
import '../../screens/auth/forgot_password_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/register_screen.dart';
import '../../screens/cart/cart_screen.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/profile/profile_screen.dart';
import '../../screens/restaurant/restaurant_screen.dart';
import '../../screens/splash/splash_screen.dart';
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
