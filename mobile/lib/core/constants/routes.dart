abstract final class Routes {
  static const String splash = '/splash';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String home = '/home';
  static const String restaurant = '/restaurant/:id';
  static const String cart = '/cart';
  static const String checkout = '/checkout';
  static const String addressPicker = '/checkout/address';
  static const String orders = '/orders';
  static const String orderDetail = '/orders/:id';
  static const String profile = '/profile';

  /// Routes a signed-out user may visit.
  static const Set<String> authRoutes = {login, register, forgotPassword};

  static String restaurantById(String id) => '/restaurant/$id';

  static String orderById(String id) => '/orders/$id';
}
