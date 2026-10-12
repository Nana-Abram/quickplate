# QuickPlate

[![Mobile](https://github.com/Nana-Abram/quickplate/actions/workflows/mobile.yml/badge.svg)](https://github.com/Nana-Abram/quickplate/actions/workflows/mobile.yml)
[![Backend](https://github.com/Nana-Abram/quickplate/actions/workflows/backend.yml/badge.svg)](https://github.com/Nana-Abram/quickplate/actions/workflows/backend.yml)

A food-delivery app built with Flutter and a small Node/Express backend: browse restaurants, build a cart, place an order and watch its status update live.

> Work in progress. Full setup instructions, screenshots and architecture notes will land here as the project is built.

## Repository layout

```
mobile/    Flutter app (Provider, go_router, Dio, Firebase)
backend/   Node 20 + Express REST API (firebase-admin, zod)
docs/      Spec, architecture, task plan and decision log
```

## Docs

- [Product spec](docs/SPEC.md)
- [Architecture](docs/ARCHITECTURE.md)
- [Task plan](docs/TASKS.md)
- [Decisions](docs/DECISIONS.md)

## Performance

Two concrete improvements from a rebuild audit (every widget that watched a whole provider was reviewed):

1. **The restaurant list rebuilds only when its rows change.** It used to watch all of `RestaurantsProvider`, so fetching the next page (which flips an `isLoadingMore` flag) rebuilt every visible card. It now selects just the list and whether a footer is needed; the footer watches its own loading state. Checkout got the same treatment for the cart.
2. **Images are decoded at the size they are drawn.** `AppNetworkImage` passes `memCacheWidth` (drawn width × device pixel ratio) to `cached_network_image`, so an 88 dp menu thumbnail decodes at about 264 px instead of the 600 × 400 source. Less memory per image and a faster first paint in long lists.

To check rebuilds yourself, run `flutter run --profile` and open the Flutter DevTools Performance view with "Track widget rebuilds" on.

