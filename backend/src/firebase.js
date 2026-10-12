import { readFileSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

import { cert, initializeApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { getFirestore } from 'firebase-admin/firestore';
import { getMessaging } from 'firebase-admin/messaging';

const backendRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');

function loadServiceAccount(config) {
  // Inline JSON wins so hosts like Render can pass the key as a secret.
  if (config.serviceAccountJson) {
    return JSON.parse(config.serviceAccountJson);
  }
  if (config.credentialsPath) {
    // Resolved from the backend folder so `npm run` works from any directory.
    const keyPath = path.resolve(backendRoot, config.credentialsPath);
    return JSON.parse(readFileSync(keyPath, 'utf8'));
  }
  throw new Error(
    'Firebase credentials missing. Set GOOGLE_APPLICATION_CREDENTIALS or ' +
      'FIREBASE_SERVICE_ACCOUNT_JSON (see docs/MANUAL_SETUP.md).',
  );
}

/** Initialises the Firebase Admin SDK and returns the clients the API uses. */
export function initFirebase(config) {
  const app = initializeApp({ credential: cert(loadServiceAccount(config)) });

  return {
    db: getFirestore(app),
    auth: getAuth(app),
    messaging: getMessaging(app),
  };
}
