import { COLLECTIONS } from '../utils/collections.js';

// Enough for a few devices per user; older tokens are dropped first.
const MAX_TOKENS = 10;

export function createUserService({ db, now = () => new Date() }) {
  /** Stores an FCM token for the user, creating the user document if needed. */
  async function registerDeviceToken(user, token) {
    const ref = db.collection(COLLECTIONS.users).doc(user.uid);

    await db.runTransaction(async (transaction) => {
      const doc = await transaction.get(ref);
      const existing = doc.exists ? (doc.data().fcmTokens ?? []) : [];
      const fcmTokens = [...existing.filter((t) => t !== token), token].slice(-MAX_TOKENS);

      if (doc.exists) {
        transaction.update(ref, { fcmTokens });
      } else {
        transaction.set(ref, { displayName: user.name ?? '', fcmTokens, createdAt: now() });
      }
    });
  }

  return { registerDeviceToken };
}
