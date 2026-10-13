# Decisions

Choices made where the spec was silent or ambiguous, one line each, grouped by area.

## Project and tooling

- Android package and iOS bundle id are `com.abraham.quickplate`. `flutter create` ran with `--org com.abraham`, because `--org com.abraham.quickplate` would append the project name and produce `com.abraham.quickplate.quickplate`.
- The analyzer runs with `strict-casts` and `strict-raw-types` on top of the lint rules in ARCHITECTURE.md, to catch unsafe JSON casts in hand-written models.
- `.gitattributes` forces LF line endings so the repo looks the same on Windows, macOS and Linux.
- CI is split into `mobile.yml` and `backend.yml` (path-filtered, one badge each) and pins Flutter 3.47.5 so local and CI analysis agree. Mobile runs analyze, a format check and tests with coverage; backend runs `npm test`.
- `.env` is bundled as an app asset, so CI copies `.env.example` to `.env` before building.
- Pushes to `main` also build a release APK as a CI artifact. Without a signing key it is signed with the debug key, and its API URL comes from the `API_BASE_URL` repository variable when set.
- Release signing reads a gitignored `android/key.properties`; without it, release builds fall back to the debug key.
- The Firebase project id lives in `backend/.firebaserc`. It is not a secret.
- The app icon and splash use the Material "delivery_dining" glyph on the brand orange (`flutter_launcher_icons`, `flutter_native_splash`). Splash colours match the theme's surface colours, so the hand-off to the Flutter splash is seamless.

## Backend

- Express 5, whose router forwards rejected promises to the error handler, so routes need no async wrapper.
- Rate limiting is a small in-memory, per-IP fixed-window middleware instead of `express-rate-limit`, which is not on the approved dependency list. Over-limit requests get 429 with the extra error code `rate_limited`.
- Restaurant search is a case-insensitive prefix match on the name (stored as `nameLower`), because Firestore has no full-text search.
- Restaurant pagination uses Firestore `startAfter`; the cursor is the id of the last restaurant on the page.
- Menu items have an extra `sortOrder` integer so menus and their category groups keep a deliberate order.
- `POST /orders`: a closed restaurant or unavailable item is 409 `conflict` (valid request, wrong state); an item id not on that menu is 400 `validation_error`. The same menu item may appear on several lines, for example with different notes.
- `GET /orders` returns `{ items }` (newest 50) to match the shape of `GET /restaurants`.
- `SIM_STEP_SECONDS=0` turns the simulator off. The demo `advance` endpoint restarts the order's timer so the next automatic step is a full interval away.
- FCM tokens are capped at 10 per user and pruned only on `registration-token-not-registered` or `invalid-registration-token`, because `invalid-argument` can also mean a bad payload.
- Tests inject in-memory fakes of Firestore, Auth and Messaging through `createApp`/`createServices` instead of mocking modules, so the real services and routes run under test.

## App architecture

- An `AppUser` model keeps Firebase's `User` type inside the data layer.
- `AuthInterceptor` attaches the ID token to every request while signed in (public endpoints ignore it) instead of tagging protected routes. A retry after a 401 keeps the refreshed token.
- Only 409 `conflict` messages from the API are shown to users, because the backend writes them for people. Every other error uses the app's own message.
- While the session is unknown, the router parks on `/splash?from=<location>` and resumes that location after sign-in, so deep links survive a cold start.
- Debug builds allow cleartext HTTP to reach the local API; release builds do not.
- Screen-scoped providers (menu, tracking, address picker) guard `notifyListeners` after dispose, because the user can leave while a request is in flight.

## Auth

- `AuthService` listens to `userChanges()` rather than `authStateChanges()`, so the display name set just after registration reaches the UI.
- The display name lives in the Firebase Auth profile; the backend creates `users/{uid}` when the first device token arrives.
- A wrong password and an unknown email share one message, and the reset screen never says whether an account exists, so the app does not reveal which emails are registered.
- New passwords need at least 8 characters (Firebase's minimum is 6). Sign-in accepts any non-empty password so older accounts still work.
- `AuthProvider` keeps one `actionState` for all auth forms; each form clears it when it opens.

## Browse and cart

- Home category chips come from a constant list that matches the seeded categories, because the API has no categories endpoint.
- The 400 ms search debounce lives in `RestaurantsProvider`, so it is unit tested. A generation counter discards responses for an older search or filter.
- `RestaurantRepository` remembers restaurants from list pages so the detail header draws instantly; the menu is always fetched fresh.
- Offline, the repository returns the last unfiltered first page from memory with an "offline" strip and a retry. Searches, filters and later pages are never served stale.
- Restaurant detail uses one tab per menu category (`NestedScrollView` + `TabBarView`) for sticky tabs, instead of one long list with scroll-synced tabs. It is simpler and keeps each tab's scroll position.
- `Restaurant` flattens `location` into `latitude`/`longitude`; `toJson` rebuilds the API shape.
- Money shows as `GH₵45.50`; a 0 delivery fee shows as "Free".
- The cart lives in memory only, as the spec allows.
- The same dish with different notes is a separate cart line; the same dish with the same notes merges.
- `CartProvider.addItem` returns an `AddToCartResult` instead of showing UI, so the "start a new cart?" question stays in the widget layer. It also refuses closed restaurants, unavailable dishes, and more than 20 of a line or 30 lines, mirroring the API.
- After "Keep cart" the item sheet stays open, so the user can change their mind.
- Snackbars with an action set `persist: false` where they are only shortcuts; in this Flutter version they otherwise stay until dismissed.

## Checkout and orders

- The map picker keeps the pin fixed at the centre: dragging or tapping moves the location under it. It starts at the last chosen address, else the cart's restaurant, else Kumasi city centre.
- There is no reverse geocoding (it would need another service). The user types the address line and the pin supplies the coordinates.
- There is no distance check between restaurant and delivery address; the spec does not ask for one.
- Location is optional: a refused permission shows a hint and the map still works. A permanent refusal offers a shortcut to Settings.
- Saved addresses live on the user's own Firestore document (`users/{uid}.savedAddresses`, newest first, at most 10), which the security rules let only the owner read and write. Checkout defaults to the newest one and offers the rest in a sheet.
- After a successful order the app navigates to `/orders/:id` first and then clears the cart, so checkout never flashes its empty state.
- `/orders/:id` is one screen for both live tracking and order detail.
- `OrderStreamService` converts Firestore `Timestamp`s to ISO strings, so a single `Order.fromJson` reads both REST and Firestore data.
- Tracking loads the order over REST first, then listens to Firestore. If the listener errors it polls REST every 10 seconds and says live updates are paused.
- Orders have no ETA field, so the arrival estimate is the order time plus the restaurant's `etaMinutes` (or 40 minutes if the restaurant is not cached).
- The order history reloads every time its screen opens, since statuses change in the background.
- The demo control (long-press on the tracking header) exists only in debug builds and needs `ENABLE_DEMO_ENDPOINTS=true`.
- The map credit is a small custom widget, because flutter_map's built-in one overflowed narrow maps with large text.

## Push notifications

- FCM "notification" messages let Android show pushes in the tray by itself in the background, so no background handler or local-notifications package is needed. They use FCM's default channel.
- While the app is open Android does not display pushes, so the app shows them as a snackbar with a "View" action.
- The device registers its token on sign-in and on every refresh. On sign-out the token is deleted, so a shared phone stops getting the previous user's updates.
- A tapped notification is handled once per FCM message id, because after a cold start the plugin can report the same tap twice. On the splash it navigates with `go`, afterwards with `push`, so Back returns to the previous screen.
- Android 13's `POST_NOTIFICATIONS` permission comes from the firebase_messaging plugin's manifest and is requested through `FirebaseMessaging.requestPermission()`.

## Polish

- The theme choice is saved on the device with `shared_preferences` (approved for this after Phase 11) and read in `main` before the first frame, so the app never flashes the wrong theme. A missing or unreadable value falls back to the system theme.
- The rebuild audit reviewed every widget that watched a whole provider; two were narrowed with `select`. Images are decoded at their drawn width. See the README's Performance section.
- The sample restaurants are invented, so no real business is shown with made-up prices or ratings. Dishes, neighbourhoods and prices follow 2025-26 Accra and Kumasi menus.
- Food photos are openly licensed (CC0, CC BY, CC BY-SA) and loaded by URL from their hosts at about 1024 px, so the repo stays small. Each is credited in `docs/PHOTO_CREDITS.md`; only the sign-in hero is bundled.
- Plus Jakarta Sans (SIL Open Font License) is bundled as asset files rather than fetched with `google_fonts`, which is not on the approved dependency list and would need a network call on first launch.
- The home header is a deep orange gradient with soft painted circles; white text on it passes WCAG AA. An earlier kente band and kente accent colours were removed after review.
- The home header, categories and "Top rated" carousel are slivers in the restaurant list's scroll view. They stay mounted across loading, empty and error states, so the search field keeps its text and focus.
- "Top rated" shows the five best-rated open restaurants from the first unfiltered page and is picked once per reload, so it does not reshuffle while more pages load.
- Accessibility is checked by widget tests: tap-target size, labelled tap targets and text contrast (light and dark) on the main screens, plus layout at double text size.
