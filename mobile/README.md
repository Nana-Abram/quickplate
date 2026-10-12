# QuickPlate mobile

Flutter app for QuickPlate. See the [root README](../README.md) and the [architecture doc](../docs/ARCHITECTURE.md).

## Setup

1. Firebase: run `flutterfire configure` in this folder (see [`docs/MANUAL_SETUP.md`](../docs/MANUAL_SETUP.md)). It generates `lib/firebase_options.dart` and `android/app/google-services.json`.
2. Copy `.env.example` to `.env` and set `API_BASE_URL`:
   - Android emulator: `http://10.0.2.2:4000/v1`
   - Real phone on the same Wi-Fi: `http://<your-computer-LAN-IP>:4000/v1`
3. Start the backend (`cd ../backend && npm run dev`).

## Commands

```sh
flutter pub get
flutter analyze
flutter test
flutter run
```

## Troubleshooting

- **Black screen on an emulator:** some emulator GPUs fail with Flutter's Impeller renderer. Run `flutter run --no-enable-impeller`, or set the AVD's graphics to "Hardware" in Android Studio's Device Manager.
