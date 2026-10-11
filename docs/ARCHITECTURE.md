# QuickPlate: Architecture

## Mobile folder structure

```
mobile/lib/
  main.dart                    Firebase init, dotenv load, runApp
  app.dart                     MaterialApp.router, theme, MultiProvider
  core/
    constants/                 routes.dart, api_endpoints.dart, firestore_paths.dart
    errors/                    app_exception.dart (NetworkException, AuthException, ...)
    network/                   dio_client.dart, auth_interceptor.dart
    theme/                     app_theme.dart, colors.dart
    utils/                     money.dart, validators.dart, debouncer.dart
    router/                    app_router.dart (go_router, auth redirect)
  data/
    models/                    restaurant.dart, menu_item.dart, cart_item.dart,
                               order.dart, order_status.dart, address.dart
    services/                  restaurant_api_service.dart, order_api_service.dart,
                               auth_service.dart, order_stream_service.dart,
                               notification_service.dart, location_service.dart
    repositories/              restaurant_repository.dart, order_repository.dart,
                               auth_repository.dart
  providers/
    view_state.dart            enum ViewState
    auth_provider.dart
    restaurants_provider.dart  list, search, category filter, pagination
    menu_provider.dart         menu for one restaurant
    cart_provider.dart         in-memory cart, totals
    orders_provider.dart       history, place order, cancel
    order_tracking_provider.dart  live stream of one order
    theme_provider.dart
  screens/
    splash/ auth/ home/ restaurant/ cart/ checkout/ tracking/ orders/ profile/
  widgets/                     shared: app_button, app_text_field, error_view,
                               empty_view, shimmer_list, restaurant_card,
                               price_text, status_timeline
mobile/test/
  providers/ repositories/ widgets/ helpers/
```

## Layering rules

```
Screen / Widget  ->  Provider (ChangeNotifier)  ->  Repository  ->  Service  ->  Dio / Firebase
```

- **Services** talk to the outside world and return models or throw `AppException`.
- **Repositories** compose services and hold simple caching. They are the only thing providers know about.
- **Providers** hold UI state and expose methods. They catch `AppException` and set `ViewState.error` with a user-readable message.
- **Widgets** read state with `context.watch`, `context.read` or `Selector`. No async work in `build`.

## Provider setup (in `app.dart`)

Create infrastructure once at the top, then providers that depend on it.

```dart
MultiProvider(
  providers: [
    // Infrastructure (plain objects)
    Provider<Dio>(create: (_) => buildDio()),
    Provider<AuthService>(create: (_) => AuthService()),
    Provider<RestaurantApiService>(create: (c) => RestaurantApiService(c.read<Dio>())),
    Provider<OrderApiService>(create: (c) => OrderApiService(c.read<Dio>())),
    Provider<OrderStreamService>(create: (_) => OrderStreamService()),
    Provider<RestaurantRepository>(create: (c) => RestaurantRepository(c.read())),
    Provider<OrderRepository>(create: (c) => OrderRepository(c.read(), c.read())),
    Provider<AuthRepository>(create: (c) => AuthRepository(c.read())),

    // State
    ChangeNotifierProvider(create: (c) => ThemeProvider()),
    ChangeNotifierProvider(create: (c) => AuthProvider(c.read())),
    ChangeNotifierProvider(create: (c) => CartProvider()),
    ChangeNotifierProvider(create: (c) => RestaurantsProvider(c.read())),
    ChangeNotifierProxyProvider<AuthProvider, OrdersProvider>(
      create: (c) => OrdersProvider(c.read()),
      update: (c, auth, previous) => previous!..onAuthChanged(auth.user),
    ),
  ],
  child: const QuickPlateApp(),
)
```

Screen-scoped providers (`MenuProvider`, `OrderTrackingProvider`) are created in the route builder with `ChangeNotifierProvider` so they dispose with the screen and cancel their stream subscriptions in `dispose()`.

`CartProvider` rules:
- Holds `restaurantId` and a list of `CartItem`. Adding an item from a different restaurant asks the user to confirm clearing the cart first.
- Exposes `subtotalPesewas`, `itemCount`, `isEmpty`. Notifies listeners only on real changes.

## Networking

- `dio_client.dart`: base URL from `.env` (`API_BASE_URL`), 10 s connect and 15 s receive timeouts.
- `auth_interceptor.dart`: attaches a fresh Firebase ID token (`getIdToken()`) to authenticated requests. On a 401 it refreshes the token once and retries.
- Map `DioException` to `AppException` in one place (`error_mapper.dart`).
- Log requests only in debug mode.

## Auth and routing

- `go_router` with `refreshListenable: authProvider`. Redirect rules: signed out goes to `/login`, signed in on an auth route goes to `/home`.
- Routes: `/splash`, `/login`, `/register`, `/forgot-password`, `/home`, `/restaurant/:id`, `/cart`, `/checkout`, `/orders`, `/orders/:id`, `/profile`.

## Live tracking

`OrderStreamService.watchOrder(orderId)` returns `Stream<Order>` from `orders/{id}.snapshots()`. `OrderTrackingProvider` subscribes, maps to `Order`, and cancels in `dispose()`. The REST `GET /orders/:id` is used for the first load and as a fallback if the stream errors.

## Push notifications

- `NotificationService`: request permission, get the token, call `PUT /me/device-token`, listen for `onTokenRefresh`.
- Foreground messages show an in-app `SnackBar`. Tapping a notification deep-links to `/orders/:id` (payload carries `orderId`).
- Backend sends the FCM message whenever an order's status changes.

## Backend structure

```
backend/
  package.json                 "type": "module"
  .env.example
  src/
    server.js                  start HTTP server
    app.js                     express app, middleware, route mounting
    config.js                  env parsing and validation (zod)
    firebase.js                admin init (service account from env path or JSON)
    middleware/                auth.js (verify ID token), error.js, validate.js
    routes/                    restaurants.js, orders.js, me.js, health.js
    services/                  restaurantService.js, orderService.js,
                               notificationService.js, orderSimulator.js
    schemas/                   zod schemas for request bodies and queries
    utils/                     errors.js (HttpError), pagination.js
  scripts/seed.js              seed restaurants and menu items
  tests/                       supertest + vitest, Firestore/Auth mocked
  Dockerfile                   optional, for deployment
  firestore.rules              security rules from SPEC.md
```

Backend rules:
- Routes are thin: validate, call a service, return JSON. Business logic lives in services.
- Totals are computed from Firestore prices, never from client input.
- The simulator uses `setTimeout` chains keyed by order id. It must be safe to restart: on boot, do not resume old orders.
- Add `helmet`, `cors` (configurable origin) and a basic rate limit.

## Extra lint rules (`mobile/analysis_options.yaml`)

Include `flutter_lints` and enable: `prefer_const_constructors`, `prefer_const_literals_to_create_immutables`, `avoid_print`, `always_declare_return_types`, `prefer_final_locals`, `unawaited_futures`, `use_build_context_synchronously`, `directives_ordering`.

## Tests to include

Mobile:
- `CartProvider`: add, remove, quantity, switch restaurant, totals
- `RestaurantsProvider`: loading, success, empty, error, pagination (mock repository)
- `AuthProvider`: sign-in success and failure (mock repository)
- `Money` formatting
- Widget test: `RestaurantCard`, and `CartScreen` empty state

Backend:
- `POST /orders` happy path, unavailable item, closed restaurant, tampered price ignored, unauthenticated
- `GET /orders/:id` forbidden for another user
- Cancel only when `placed`
