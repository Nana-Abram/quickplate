# QuickPlate: Steps only you can do

Claude Code can't click through consoles. Do these before the phase that needs them.

## Before Phase 0
1. **Tools installed:** Flutter (stable), Android Studio or SDK, Node 20+, Git, and Claude Code.
2. **GitHub:** create an empty public repo named `quickplate` (no README, no .gitignore). Add it as `origin` when Claude Code asks.
3. **Android package name:** default is `com.abraham.quickplate`. Change it in `TASKS.md` Phase 0 if you want a different one. It can't be changed painlessly later.

## Before Phase 1 (backend)
1. Go to the Firebase console and create a project named `quickplate` (Google Analytics optional, can be off).
2. **Authentication:** Sign-in method, enable **Email/Password**.
3. **Firestore:** create a database in production mode. Pick a region close to you (`eur3` or `europe-west` is fine).
4. **Service account for the backend:** Project settings, Service accounts, Generate new private key. Save it as `backend/serviceAccountKey.json`. It is gitignored. **Never commit or share it.**
5. In `backend/.env` set:
```
PORT=4000
GOOGLE_APPLICATION_CREDENTIALS=./serviceAccountKey.json
ENABLE_DEMO_ENDPOINTS=true
SIM_STEP_SECONDS=20
CORS_ORIGIN=*
```

## Before Phase 2 (mobile Firebase)
1. Install the CLIs: `npm i -g firebase-tools`, then `dart pub global activate flutterfire_cli`.
2. `firebase login`, then inside `mobile/` run `flutterfire configure`, select the `quickplate` project and the Android (and iOS if prompted) platforms. This generates `firebase_options.dart`.
3. Create `mobile/.env` from `.env.example`. For the Android emulator use `API_BASE_URL=http://10.0.2.2:4000/v1`. For a real phone on Wi-Fi use your computer's LAN IP, e.g. `http://192.168.1.20:4000/v1`.
4. Seed data: in `backend/` run `npm run seed`.

## Before Phase 8 (push)
- Test on a **real Android device** (emulators without Google Play services are unreliable for FCM).
- Android 13+ asks for notification permission at runtime. Allow it.

## Before Phase 11 (release)
1. Backend hosting: deploy `backend/` to Render (free web service). Set the env vars above in the dashboard, and provide the service account as the `FIREBASE_SERVICE_ACCOUNT_JSON` secret (Claude Code will add support for reading it in `firebase.js` if you tell it you are deploying). The free tier sleeps after inactivity, so the first request after idle takes about 30 seconds. Say so in the README.
2. Set `API_BASE_URL` for release builds to the Render URL.
3. Create a release keystore (`keytool -genkey ...`), keep it outside the repo, and configure `key.properties` (gitignored).
4. Record a 20 to 30 second screen capture of the full flow, convert it to a GIF, and take 4 to 6 screenshots for the README.
5. Create a GitHub Release `v1.0.0` and attach the APK.
