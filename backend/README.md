# QuickPlate backend

REST API for QuickPlate, built with Node 20+, Express 5, `firebase-admin` and `zod`. It serves restaurants and menus, creates orders with server-side totals, and plays the restaurant and rider by advancing order status on a timer. Order changes reach the app through Firestore listeners and FCM pushes.

## Setup

1. Complete the Firebase steps in [`docs/MANUAL_SETUP.md`](../docs/MANUAL_SETUP.md) (project, Email/Password auth, Firestore, service account key saved as `backend/serviceAccountKey.json`).
2. Install and configure:
   ```sh
   cd backend
   npm install
   cp .env.example .env
   ```
3. Deploy the Firestore security rules and indexes (needs `npm i -g firebase-tools` and `firebase login`). Set your own project id in `.firebaserc` first if you are not using `quickplate-d2881`. Indexes take a few minutes to build.
   ```sh
   firebase deploy --only firestore
   ```
4. Load the sample restaurants (safe to run again):
   ```sh
   npm run seed
   ```
5. Start the API:
   ```sh
   npm run dev     # restarts on file changes
   npm start       # plain start
   ```
   It listens on `http://localhost:4000/v1`. The Android emulator reaches it at `http://10.0.2.2:4000/v1`.

## Environment variables

| Variable | Default | Purpose |
|---|---|---|
| `PORT` | `4000` | HTTP port |
| `GOOGLE_APPLICATION_CREDENTIALS` | none | Path to the service account key, relative to `backend/` |
| `FIREBASE_SERVICE_ACCOUNT_JSON` | none | The key's JSON contents. Takes precedence over the path; use it on hosts like Render |
| `ENABLE_DEMO_ENDPOINTS` | `false` | Mounts `POST /v1/orders/:id/advance` |
| `SIM_STEP_SECONDS` | `20` | Seconds between simulated status steps. `0` turns the simulator off |
| `CORS_ORIGIN` | `*` | Allowed origin(s), comma separated |
| `RATE_LIMIT_PER_MINUTE` | `120` | Requests per IP per minute |

The config is validated with zod at startup, so a bad value stops the server with a clear message.

## API

Base path `/v1`. Routes marked with 🔒 need `Authorization: Bearer <Firebase ID token>`.

| Method | Path | Notes |
|---|---|---|
| GET | `/health` | `{ "status": "ok" }` |
| GET | `/restaurants` | `q` (name prefix), `category`, `limit` (1 to 30, default 10), `cursor`. Returns `{ items, nextCursor }` |
| GET | `/restaurants/:id` | One restaurant |
| GET | `/restaurants/:id/menu` | `{ categories: [{ name, items }] }` in menu order |
| POST | `/orders` 🔒 | Creates an order. Prices come from Firestore, never from the request |
| GET | `/orders` 🔒 | `{ items }`: the caller's 50 most recent orders, newest first |
| GET | `/orders/:id` 🔒 | Owner only (403 otherwise) |
| POST | `/orders/:id/cancel` 🔒 | Only while `placed`, otherwise 409 |
| POST | `/orders/:id/advance` 🔒 | Demo only: moves the order one status forward |
| PUT | `/me/device-token` 🔒 | `{ "token": "<FCM token>" }`, returns 204 |

Errors always look like `{ "error": { "code": "...", "message": "..." } }`, with codes `validation_error` (400), `unauthorized` (401), `forbidden` (403), `not_found` (404), `conflict` (409), `rate_limited` (429) and `internal` (500).

Order status flow: `placed → accepted → preparing → on_the_way → delivered`, or `placed → cancelled`.

## Tests

```sh
npm test
```

Tests run the real routes and services with supertest against in-memory fakes of Firestore, Auth and Messaging (`tests/helpers/`). They need no network or credentials.

## Layout

```
src/
  server.js        boot: config, Firebase, services, HTTP server
  app.js           Express app: middleware and routes (takes its dependencies as arguments)
  config.js        env parsing and validation
  firebase.js      Admin SDK init
  middleware/      auth, validation, rate limit, error handling
  routes/          thin handlers: validate, call a service, send JSON
  services/        business logic: restaurants, orders, simulator, notifications, users
  schemas/         zod request schemas
  utils/           errors, collection names, order status flow
scripts/seed.js    sample data loader
firestore.rules    client access rules
```
