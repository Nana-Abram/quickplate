# QuickPlate: Product Spec

## Goal

A customer-facing food-delivery app: browse restaurants, build a cart, place an order, and watch its status update live. The restaurant and rider sides are simulated by the backend.

Currency: GHS. Seed data is set in Kumasi and Accra.

## Scope

In scope (v1):
1. Email/password auth (Firebase Auth), persistent session, password reset
2. Browse and search restaurants, filter by category
3. Restaurant detail with a menu grouped by category
4. Cart (single restaurant at a time), quantity edits, item notes
5. Checkout with a delivery address picked on a map, and payment method (cash on delivery or "mock card", no real payments)
6. Order placement via REST, with totals calculated on the server
7. Live order tracking via Firestore snapshot listener, with a status timeline
8. Order history and order detail
9. Push notifications on order status change (FCM)
10. Profile screen: name, saved addresses (local list is fine), sign out, light/dark theme toggle

Out of scope: real payments, restaurant app, rider app, Google sign-in, i18n, admin panel.

## Screens

| Screen | Notes |
|---|---|
| Splash | Decides route from auth state |
| Login / Register / Forgot password | Form validation, inline errors |
| Home | Search bar, category chips, restaurant list (paginated), pull-to-refresh |
| Restaurant detail | Header image, info, sticky category tabs, menu items |
| Item sheet | Bottom sheet: quantity, notes, add to cart |
| Cart | Line items, subtotal, delivery fee, total, clear cart |
| Checkout | Address (map picker with "use my location"), payment method, place order |
| Order tracking | Status timeline, ETA text, map showing delivery address, cancel while status is `placed` |
| Orders | History list, tap for detail |
| Profile | Settings and sign out |

## Order status flow

`placed -> accepted -> preparing -> on_the_way -> delivered`, plus `cancelled` (only from `placed`).

The backend simulator advances status on a timer after an order is created (default 20 seconds per step, configurable by `SIM_STEP_SECONDS`). A demo endpoint can advance an order manually.

## Data model

### Firestore (written only by the backend via Admin SDK)

`restaurants/{restaurantId}`
```
name, description, imageUrl, categories: [string], rating: number,
deliveryFeePesewas: int, etaMinutes: int, isOpen: bool,
location: {lat, lng}, createdAt
```

`restaurants/{restaurantId}/menuItems/{itemId}`
```
name, description, imageUrl, category, pricePesewas: int, isAvailable: bool
```

`orders/{orderId}`
```
userId, restaurantId, restaurantName,
items: [{menuItemId, name, unitPricePesewas, quantity, notes}],
subtotalPesewas, deliveryFeePesewas, totalPesewas,
deliveryAddress: {label, line1, lat, lng},
paymentMethod: "cash_on_delivery" | "mock_card",
status, statusHistory: [{status, at}],
createdAt, updatedAt
```

`users/{uid}`
```
displayName, fcmTokens: [string], createdAt
```

### Security rules

- `restaurants` and `menuItems`: public read, no client write
- `orders`: a signed-in user may read only documents where `userId == request.auth.uid`. No client write.
- `users/{uid}`: the owner may read and write their own document only

## REST API (base path `/v1`)

All JSON. Authenticated routes need `Authorization: Bearer <Firebase ID token>`.

Error shape: `{ "error": { "code": "string", "message": "string" } }`
Codes: `validation_error` (400), `unauthorized` (401), `forbidden` (403), `not_found` (404), `conflict` (409), `internal` (500).

| Method | Path | Auth | Description |
|---|---|---|---|
| GET | `/health` | no | `{ "status": "ok" }` |
| GET | `/restaurants` | no | Query: `q`, `category`, `limit` (default 10, max 30), `cursor`. Returns `{ items: [...], nextCursor: string|null }` |
| GET | `/restaurants/:id` | no | Restaurant detail |
| GET | `/restaurants/:id/menu` | no | `{ categories: [{ name, items: [...] }] }` |
| POST | `/orders` | yes | Create an order (body below). Returns 201 with the order |
| GET | `/orders` | yes | Current user's orders, newest first |
| GET | `/orders/:id` | yes | One order (owner only) |
| POST | `/orders/:id/cancel` | yes | Allowed only when status is `placed`, else 409 |
| POST | `/orders/:id/advance` | yes | Demo only. Enabled when `ENABLE_DEMO_ENDPOINTS=true` |
| PUT | `/me/device-token` | yes | Body `{ "token": string }`. Stores the FCM token |

`POST /orders` body:
```json
{
  "restaurantId": "string",
  "items": [{ "menuItemId": "string", "quantity": 2, "notes": "no onions" }],
  "deliveryAddress": { "label": "Home", "line1": "string", "lat": 6.69, "lng": -1.62 },
  "paymentMethod": "cash_on_delivery"
}
```
Server rules: reject unavailable items or a closed restaurant, ignore any client-sent prices, quantity 1 to 20, max 30 line items.

## Non-functional requirements

- Cold start to first content under 3 seconds on a mid-range Android phone
- Lists are lazy (`ListView.builder`), images cached, no unnecessary rebuilds (use `Selector`/`Consumer` scoped to the smallest widget)
- Works offline for already-loaded restaurants where cheap to do (cache last restaurant page in memory). Show a clear offline error otherwise.
- Accessible: semantic labels on icon buttons, tap targets of at least 48dp, text scales without overflow
- Android is the primary target. iOS builds should not be broken, but they are not tested.
