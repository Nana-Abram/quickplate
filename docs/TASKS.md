# QuickPlate: Task Plan

Work one phase at a time on its own branch, then stop for review. Tick boxes as you go. See `CLAUDE.md` for the definition of done.

## Phase 0: Repo bootstrap (`feat/phase-0-bootstrap`)
- [ ] Create the monorepo layout from `CLAUDE.md` and `git init` with `main`
- [ ] Root `.gitignore` (Flutter, Node, `.env`, `serviceAccountKey.json`, keystores)
- [ ] `flutter create mobile --org com.abraham.quickplate --project-name quickplate --platforms android,ios` (confirm the org with the user first if `docs/MANUAL_SETUP.md` says otherwise)
- [ ] Add dependencies from `CLAUDE.md`, set up `analysis_options.yaml` per `ARCHITECTURE.md`
- [ ] Create the empty folder skeleton from `ARCHITECTURE.md` with a minimal running app
- [ ] Root `README.md` stub, `docs/DECISIONS.md`, `.github/workflows/ci.yml` running `flutter analyze` and `flutter test`
**Done when:** the app launches to a placeholder screen, CI file exists, first commits are clean.

## Phase 1: Backend (`feat/phase-1-backend`)
- [ ] Express app with config validation, `helmet`, `cors`, rate limit, error middleware, `/v1/health`
- [ ] Firebase Admin init; auth middleware verifying ID tokens
- [ ] `scripts/seed.js`: 8 restaurants (Kumasi and Accra), 8 to 12 menu items each, several categories (e.g. Local, Fast Food, Pizza, Healthy, Drinks). Use placeholder image URLs from `https://picsum.photos/seed/<name>/600/400`.
- [ ] Restaurants endpoints with search, category filter and cursor pagination
- [ ] Orders endpoints: create (server-computed totals), list, get, cancel
- [ ] `orderSimulator.js` and the demo `advance` endpoint behind `ENABLE_DEMO_ENDPOINTS`
- [ ] `notificationService.js` sends FCM on status change (no-op with a log if the user has no tokens)
- [ ] `PUT /me/device-token`
- [ ] `firestore.rules` per `SPEC.md`
- [ ] Tests listed in `ARCHITECTURE.md`, `backend/README.md` with env vars and run steps
**Done when:** `npm test` passes and every endpoint in `SPEC.md` works against the real Firebase project (needs `docs/MANUAL_SETUP.md` steps 1 to 4, ask the user if missing).

## Phase 2: App foundation (`feat/phase-2-foundation`)
- [ ] Theme (light and dark, Material 3, one brand colour), `ThemeProvider`
- [ ] Constants, `AppException` hierarchy, `error_mapper`, Dio client and auth interceptor
- [ ] Shared widgets: `AppButton`, `AppTextField`, `ErrorView`, `EmptyView`, `ShimmerList`
- [ ] `ViewState` enum, `go_router` with auth redirect, `MultiProvider` wiring
- [ ] Firebase init via `firebase_options.dart` (from `flutterfire configure`, step 5 in `MANUAL_SETUP.md`)
**Done when:** the app routes between splash and placeholder screens based on auth state.

## Phase 3: Auth (`feat/phase-3-auth`)
- [ ] `AuthService`, `AuthRepository`, `AuthProvider`
- [ ] Login, Register (name, email, password), Forgot password screens with validation
- [ ] Friendly mapping of Firebase auth errors (wrong password, user not found, email in use, network)
- [ ] Persistent session, sign-out from a temporary profile screen
- [ ] Tests for `AuthProvider`
**Done when:** a user can register, sign out, sign in, reset a password, and relaunch while staying signed in.

## Phase 4: Browse (`feat/phase-4-browse`)
- [ ] Models, `RestaurantApiService`, `RestaurantRepository`, `RestaurantsProvider`
- [ ] Home: debounced search (400 ms), category chips, infinite scroll, pull-to-refresh, shimmer, empty and error views
- [ ] `RestaurantCard` with cached image, rating, ETA, delivery fee, closed badge
- [ ] Restaurant detail with `MenuProvider`, category tabs, item rows
- [ ] Tests for `RestaurantsProvider` and a `RestaurantCard` widget test
**Done when:** browsing, searching and filtering work against the live backend, with all five states visible.

## Phase 5: Cart (`feat/phase-5-cart`)
- [ ] `CartItem`, `CartProvider` (rules in `ARCHITECTURE.md`)
- [ ] Item bottom sheet (quantity, notes), cart badge on the home app bar
- [ ] Cart screen with quantity steppers, swipe to remove, totals, "clear cart", different-restaurant confirmation dialog
- [ ] `Money` util and tests for `CartProvider`
**Done when:** cart behaviour matches `SPEC.md` and the unit tests pass.

## Phase 6: Checkout (`feat/phase-6-checkout`)
- [ ] `LocationService` (permission flow, graceful denial)
- [ ] Map picker with `flutter_map`: tap or drag to set the pin, "use my location", editable address line, label
- [ ] Payment method selector
- [ ] `OrderApiService.create`, `OrdersProvider.placeOrder`, loading state on the button, error handling, clear cart on success
- [ ] Navigate to the tracking screen after a successful order
**Done when:** an order is created on the backend and appears in Firestore.

## Phase 7: Orders and tracking (`feat/phase-7-orders`)
- [ ] `OrderStreamService`, `OrderTrackingProvider` with proper stream disposal
- [ ] Tracking screen: `StatusTimeline` widget, ETA text, delivery address map, cancel button (only while `placed`), fallback to REST on stream error
- [ ] Orders history with status chips, order detail screen
- [ ] Hidden demo control (long-press the status header, debug builds only) calling `/advance`
**Done when:** status changes made by the simulator show up live without refreshing.

## Phase 8: Push notifications (`feat/phase-8-push`)
- [ ] `NotificationService`: permission, token upload, token refresh
- [ ] Foreground in-app banner, background and terminated tap deep-links to `/orders/:id`
- [ ] Android 13 notification permission handled
**Done when:** a status change triggers a notification on a real device and tapping it opens the order.

## Phase 9: Polish and performance (`feat/phase-9-polish`)
- [ ] Rebuild audit with Flutter DevTools. Scope `Consumer` and `Selector` widgets, add `const` where missing, and note two concrete improvements in the README under "Performance".
- [ ] Offline and slow-network behaviour: timeouts, retry button, in-memory cache of the last restaurant page
- [ ] Accessibility pass (semantic labels, tap targets, large text)
- [ ] Dark mode check on every screen, app icon and splash via `flutter_launcher_icons` and `flutter_native_splash`
- [ ] Profile screen finished (name, saved addresses list, theme toggle, sign out)

## Phase 10: Tests and CI (`feat/phase-10-quality`)
- [ ] Fill any gaps from the "Tests to include" list in `ARCHITECTURE.md`
- [ ] CI runs analyze, format check and tests for mobile, and tests for backend, with status badges
- [ ] Optional: a build job that uploads a release APK as a workflow artifact

## Phase 11: Documentation and release (`feat/phase-11-release`)
- [ ] Root `README.md`: one-line pitch, screenshots and demo GIF placeholders (the user will add real captures), features, tech stack, architecture diagram (Mermaid), setup steps, API summary, testing, performance notes, known limitations, roadmap
- [ ] `mobile/README.md` and `backend/README.md` kept short and accurate
- [ ] Signed release APK build instructions, tag `v1.0.0`
- [ ] `docs/DECISIONS.md` reviewed and tidied
**Done when:** a stranger can clone the repo and run the app by following the README only.
