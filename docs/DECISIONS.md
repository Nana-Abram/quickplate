# Decisions

One line per decision made where the spec was silent or ambiguous.

- Android package and iOS bundle id are `com.abraham.quickplate`: `flutter create` was run with `--org com.abraham` because `--org com.abraham.quickplate` would append the project name and produce `com.abraham.quickplate.quickplate`.
- Analyzer runs with `strict-casts` and `strict-raw-types` on top of the lint rules in ARCHITECTURE.md, to catch unsafe JSON casts in hand-written models.
- `.gitattributes` forces LF line endings so the repo looks the same on Windows, macOS and Linux.
- CI pins the Flutter version (3.47.5) so local and CI analysis agree; bump it deliberately.
- Backend uses Express 5, whose router forwards rejected promises to the error handler, so routes need no async wrapper.
- Rate limiting is a small in-memory, per-IP fixed-window middleware instead of `express-rate-limit`, which is not on the approved dependency list. Over-limit requests get 429 with the extra error code `rate_limited`.
- Restaurant search is a case-insensitive prefix match on the name (stored as `nameLower`), because Firestore has no full-text search. Real search would need a service such as Typesense or Algolia.
- Restaurant pagination uses Firestore `startAfter`, with the cursor being the id of the last restaurant on the page.
- Menu items have an extra `sortOrder` integer so menus and their category groups keep a deliberate order.
- `POST /orders`: a closed restaurant or unavailable item is 409 `conflict` (valid request, wrong state); an item id not on that restaurant's menu is 400 `validation_error`. The same menu item may appear on several lines, e.g. with different notes.
- `GET /orders` returns `{ items }` (newest 50) to match the shape of `GET /restaurants`.
- `SIM_STEP_SECONDS=0` turns the simulator off. Advancing an order through the demo endpoint restarts its timer so the next automatic step is a full interval away.
- FCM tokens are capped at 10 per user. Tokens are pruned only on `registration-token-not-registered` or `invalid-registration-token`, because `invalid-argument` can also mean a bad payload.
- Backend tests inject in-memory fakes of Firestore, Auth and Messaging through `createApp`/`createServices` instead of mocking modules, so the real services and routes run under test.
- The Firebase project id lives in `backend/.firebaserc`. It is not a secret.
- Phase 2 builds the session part of `AuthProvider` (auth state stream, sign out) because routing depends on it. Phase 3 adds sign-in, registration and password reset.
- An `AppUser` model keeps Firebase's `User` type inside the data layer.
- `ThemeProvider` keeps the chosen theme in memory only: persisting it would need `shared_preferences`, which is not an approved dependency.
- `AuthInterceptor` attaches the ID token to every request while signed in (public endpoints ignore it) instead of tagging protected routes. Retries after a 401 keep the refreshed token.
- Only 409 `conflict` messages from the API are shown to users, because the backend writes them for people. Every other error uses the app's own message.
- While the session is unknown the router parks on `/splash?from=<location>` and resumes that location after sign-in, so deep links from notifications survive a cold start.
- `.env` is bundled as an asset, so CI copies `.env.example` to `.env` before building.
- Debug builds allow cleartext HTTP to reach the local API; release builds do not.
- `AuthService` listens to Firebase `userChanges()` rather than `authStateChanges()`, so the display name set just after registration reaches the UI.
- The display name lives in the Firebase Auth profile. Registration writes nothing to Firestore; the backend creates `users/{uid}` when the first device token arrives (Phase 8).
- A wrong password and an unknown email share one message ("Incorrect email or password."), and the reset screen never says whether an account exists, so the app does not reveal which emails are registered.
- New passwords need at least 8 characters (Firebase's minimum is 6). Sign-in accepts any non-empty password so older accounts still work.
- `AuthProvider` keeps one `actionState` for all auth forms; each form clears it when it opens.
- Home category chips come from a constant list that matches the seeded categories, because the API has no categories endpoint.
- The search debounce (400 ms) lives in `RestaurantsProvider`, not the widget, so it is unit tested. A generation counter discards responses for an older search or filter.
- `RestaurantRepository` remembers restaurants from list pages so the detail header draws instantly. The menu is always fetched fresh.
- Restaurant detail uses one tab per menu category (`NestedScrollView` + `TabBarView`) for sticky tabs, instead of one long list with scroll-synced tabs. It is simpler and keeps each tab's scroll position.
- `Restaurant` flattens `location` into `latitude`/`longitude`; `toJson` rebuilds the API shape.
- Money shows as `GH₵45.50`; a 0 delivery fee shows as "Free".
- The 8 seeded restaurants fit in one page of 10, so infinite scroll is covered by provider tests rather than visible with the seed data.
