# QuickPlate: Claude Code Instructions

QuickPlate is a food-delivery mobile app (Flutter) with a small REST backend (Node/Express). It is a portfolio project for a Flutter Developer job application. Reviewers will read the code, the folder structure, the git history and the README, so quality and clarity matter more than feature count.

Read these before writing code:
- `docs/SPEC.md`: scope, screens, data model, API contract
- `docs/ARCHITECTURE.md`: folder structure, layering, Provider setup
- `docs/TASKS.md`: phased checklist. Work through it in order.

## Monorepo layout

```
quickplate/
  mobile/        Flutter app
  backend/       Node 20 + Express REST API
  docs/          SPEC.md, ARCHITECTURE.md, TASKS.md, MANUAL_SETUP.md
  .github/workflows/
  README.md
```

## Stack (fixed, do not swap)

- Flutter (latest stable) + Dart, null safety, `flutter_lints` plus the extra lints in ARCHITECTURE.md
- State management: **Provider** (`ChangeNotifier`). Do NOT use Riverpod, Bloc or GetX. The job posting names Provider explicitly.
- Navigation: `go_router`
- HTTP: `dio`
- Firebase: `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_messaging`
- Maps: `flutter_map` + `latlong2` + `geolocator` (OpenStreetMap, no API key or billing)
- UI helpers: `cached_network_image`, `shimmer`, `intl`
- Config: `flutter_dotenv` (mobile), `dotenv` (backend)
- Tests: `flutter_test`, `mocktail` (mobile); `vitest` + `supertest` (backend)
- Backend: Express, `firebase-admin`, `zod` for validation, plain JavaScript (ESM)

Ask before adding any dependency not listed here.

## Commands

Mobile (run in `mobile/`):
- `flutter pub get`
- `flutter analyze` (must show zero issues)
- `flutter test`
- `dart format .`
- `flutter run`

Backend (run in `backend/`):
- `npm install`
- `npm run dev`
- `npm test`
- `npm run seed` (loads sample restaurants into Firestore)

## Code conventions

- Dependency direction: `screens -> providers -> repositories -> services/models`. Screens never call Dio or Firebase directly. Providers never import widgets.
- Every provider that loads data exposes a `ViewState` (`idle | loading | success | empty | error`) and an error message. Every screen renders all five states.
- Models are immutable, with `fromJson`, `toJson` and `copyWith`. No code generation. Write them by hand.
- Money is stored as integer pesewas (GHS minor units) and formatted only in the UI.
- No business logic in widgets. No magic strings: routes, collection names and endpoints live in constants files.
- Use `const` constructors where possible. Split widgets that exceed about 150 lines.
- Handle errors with typed exceptions (`AppException` subclasses) mapped from Dio and Firebase errors. Never show raw exception text to the user.
- Comments explain why, not what. No commented-out code.

## Git rules

- Work on a branch per phase: `feat/phase-N-short-name`. Merge into `main` with `--no-ff` once the phase's definition of done passes.
- Conventional commits: `feat:`, `fix:`, `refactor:`, `test:`, `docs:`, `chore:`, `ci:`. Make small, meaningful commits (one concern each). Never one giant commit.
- Never commit secrets. See "Secrets" below.

## Secrets

- Never commit: `backend/serviceAccountKey.json`, any `.env`, keystores, `key.properties`.
- Commit `.env.example` files with placeholder values.
- `firebase_options.dart` and `google-services.json` are client config and may be committed. The README must note that Firestore security rules protect the data.
- If a required secret or console step is missing, stop and tell the user exactly what to do (see `docs/MANUAL_SETUP.md`). Do not invent credentials or mock around Firebase silently.

## Definition of done (every phase)

1. `flutter analyze` clean and `flutter test` green (mobile), `npm test` green (backend), where applicable
2. The phase's acceptance criteria in `docs/TASKS.md` are met
3. Loading, empty and error states exist for any new data screen
4. Checkboxes in `docs/TASKS.md` are ticked and committed
5. Stop and give the user a short summary: what was built, how to run it, anything the user must do next

## Working style

- Do one phase at a time, then stop for review. Do not start the next phase unprompted.
- If the spec is ambiguous, pick the simplest option consistent with `docs/SPEC.md`, note the decision in `docs/DECISIONS.md` (one line each), and continue.
- Do not use the GrabGo name or branding anywhere. This is an independent project.
