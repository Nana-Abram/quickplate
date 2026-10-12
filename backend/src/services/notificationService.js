import { COLLECTIONS } from '../utils/collections.js';
import { ORDER_STATUS } from '../utils/orderStatus.js';

// FCM error codes that mean the token will never work again.
const STALE_TOKEN_CODES = new Set([
  'messaging/registration-token-not-registered',
  'messaging/invalid-registration-token',
]);

const MESSAGES = {
  [ORDER_STATUS.accepted]: (name) => ['Order accepted', `${name} has accepted your order.`],
  [ORDER_STATUS.preparing]: (name) => ['Being prepared', `${name} is preparing your food.`],
  [ORDER_STATUS.onTheWay]: () => ['On the way', 'Your rider is on the way.'],
  [ORDER_STATUS.delivered]: () => ['Delivered', 'Your order has arrived. Enjoy your meal!'],
  [ORDER_STATUS.cancelled]: () => ['Order cancelled', 'Your order has been cancelled.'],
};

export function createNotificationService({ db, messaging, logger }) {
  const userRef = (uid) => db.collection(COLLECTIONS.users).doc(uid);

  async function removeTokens(uid, staleTokens) {
    await db.runTransaction(async (transaction) => {
      const doc = await transaction.get(userRef(uid));
      if (!doc.exists) return;
      const fcmTokens = (doc.data().fcmTokens ?? []).filter((t) => !staleTokens.includes(t));
      transaction.update(userRef(uid), { fcmTokens });
    });
  }

  /**
   * Sends a push for an order status change. Never throws: a failed push is
   * logged, and the status change it describes has already been saved.
   */
  async function notifyStatusChange(order) {
    const buildMessage = MESSAGES[order.status];
    if (!buildMessage) return;

    try {
      const userDoc = await userRef(order.userId).get();
      const tokens = userDoc.exists ? (userDoc.data().fcmTokens ?? []) : [];
      if (tokens.length === 0) {
        logger.info(`No device tokens for user ${order.userId}; skipped push for order ${order.id}.`);
        return;
      }

      const [title, body] = buildMessage(order.restaurantName);
      const response = await messaging.sendEachForMulticast({
        tokens,
        notification: { title, body },
        // The app reads orderId to deep-link to /orders/:id.
        data: { orderId: order.id, status: order.status },
        android: { priority: 'high' },
      });

      const staleTokens = tokens.filter((_, index) => {
        const result = response.responses[index];
        return !result.success && STALE_TOKEN_CODES.has(result.error?.code);
      });
      if (staleTokens.length > 0) await removeTokens(order.userId, staleTokens);
    } catch (error) {
      logger.error(`Failed to send push for order ${order.id}`, error);
    }
  }

  return { notifyStatusChange };
}
