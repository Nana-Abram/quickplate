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
