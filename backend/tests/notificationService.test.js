import { describe, expect, it, vi } from 'vitest';

import { createNotificationService } from '../src/services/notificationService.js';
import { COLLECTIONS } from '../src/utils/collections.js';
import { silentLogger } from '../src/utils/logger.js';
import { createFakeFirestore } from './helpers/fakeFirestore.js';
import { createFakeMessaging } from './helpers/fakeMessaging.js';

const order = { id: 'o1', userId: 'ama', restaurantName: "Adwoa's Kitchen", status: 'accepted' };

async function setup({ tokens, staleTokens = [] } = {}) {
  const db = createFakeFirestore();
  const messaging = createFakeMessaging({ staleTokens });
  const logger = { ...silentLogger, info: vi.fn(), error: vi.fn() };
  if (tokens) {
    await db.collection(COLLECTIONS.users).doc('ama').set({ fcmTokens: tokens });
  }
  const service = createNotificationService({ db, messaging, logger });
  return { db, messaging, logger, service };
}

describe('notificationService', () => {
  it('sends the status change to every device with the order id', async () => {
    const { messaging, service } = await setup({ tokens: ['t1', 't2'] });

    await service.notifyStatusChange(order);

    expect(messaging.sent).toHaveLength(1);
    expect(messaging.sent[0]).toMatchObject({
      tokens: ['t1', 't2'],
      notification: { title: 'Order accepted', body: "Adwoa's Kitchen has accepted your order." },
      data: { orderId: 'o1', status: 'accepted' },
    });
  });

  it('logs and skips when the user has no tokens', async () => {
    const { messaging, logger, service } = await setup();

    await service.notifyStatusChange(order);

    expect(messaging.sent).toHaveLength(0);
    expect(logger.info).toHaveBeenCalledWith(expect.stringContaining('No device tokens'));
  });

  it('removes tokens FCM reports as no longer registered', async () => {
    const { db, service } = await setup({ tokens: ['good', 'stale'], staleTokens: ['stale'] });

    await service.notifyStatusChange(order);

    const user = await db.collection(COLLECTIONS.users).doc('ama').get();
    expect(user.data().fcmTokens).toEqual(['good']);
  });

  it('never throws when sending fails', async () => {
    const { messaging, logger, service } = await setup({ tokens: ['t1'] });
    messaging.sendEachForMulticast = vi.fn().mockRejectedValue(new Error('fcm down'));

    await expect(service.notifyStatusChange(order)).resolves.toBeUndefined();
    expect(logger.error).toHaveBeenCalled();
  });
});
