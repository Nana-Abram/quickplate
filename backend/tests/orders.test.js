import request from 'supertest';
import { beforeEach, describe, expect, it } from 'vitest';

import { COLLECTIONS } from '../src/utils/collections.js';
import { bearer } from './helpers/fakeAuth.js';
import { addMenuItem, addRestaurant } from './helpers/fixtures.js';
import { buildTestApp } from './helpers/testApp.js';

const address = { label: 'Home', line1: '12 Prempeh II St, Adum', lat: 6.69, lng: -1.62 };

const orderBody = (overrides = {}) => ({
  restaurantId: 'adwoa',
  items: [
    { menuItemId: 'jollof', quantity: 2, notes: 'extra shito' },
    { menuItemId: 'sobolo', quantity: 1 },
  ],
  deliveryAddress: address,
  paymentMethod: 'cash_on_delivery',
  ...overrides,
});

describe('orders', () => {
  let app;
  let db;

  beforeEach(async () => {
    ({ app, db } = buildTestApp());
    await addRestaurant(db, 'adwoa', { name: "Adwoa's Kitchen", deliveryFeePesewas: 1200 });
    await addMenuItem(db, 'adwoa', 'jollof', { name: 'Jollof Rice', pricePesewas: 4500 });
    await addMenuItem(db, 'adwoa', 'sobolo', { name: 'Sobolo', pricePesewas: 1000 });
    await addMenuItem(db, 'adwoa', 'ampesi', { name: 'Ampesi', isAvailable: false });
    await addRestaurant(db, 'closed', { name: 'Closed Place', isOpen: false });
    await addMenuItem(db, 'closed', 'jollof', { pricePesewas: 4500 });
  });

  const placeOrder = (uid, body = orderBody()) =>
    request(app).post('/v1/orders').set(bearer(uid)).send(body);

  describe('POST /v1/orders', () => {
    it('creates an order with server-computed totals', async () => {
      const res = await placeOrder('ama');

      expect(res.status).toBe(201);
      expect(res.body).toMatchObject({
        userId: 'ama',
        restaurantId: 'adwoa',
        restaurantName: "Adwoa's Kitchen",
        subtotalPesewas: 2 * 4500 + 1000,
        deliveryFeePesewas: 1200,
        totalPesewas: 2 * 4500 + 1000 + 1200,
        status: 'placed',
        paymentMethod: 'cash_on_delivery',
        deliveryAddress: address,
      });
      expect(res.body.items[0]).toEqual({
        menuItemId: 'jollof',
        name: 'Jollof Rice',
        unitPricePesewas: 4500,
        quantity: 2,
        notes: 'extra shito',
      });
      expect(res.body.items[1].notes).toBe('');
      expect(res.body.statusHistory).toEqual([{ status: 'placed', at: res.body.createdAt }]);

      const stored = await db.collection(COLLECTIONS.orders).doc(res.body.id).get();
      expect(stored.data().totalPesewas).toBe(res.body.totalPesewas);
    });

    it('ignores prices sent by the client', async () => {
      const res = await placeOrder(
        'ama',
        orderBody({
          items: [{ menuItemId: 'jollof', quantity: 1, unitPricePesewas: 1, pricePesewas: 1 }],
          subtotalPesewas: 1,
          totalPesewas: 1,
        }),
      );

      expect(res.status).toBe(201);
      expect(res.body.items[0].unitPricePesewas).toBe(4500);
      expect(res.body.totalPesewas).toBe(4500 + 1200);
    });

    it('rejects an unavailable item with 409', async () => {
      const res = await placeOrder(
        'ama',
        orderBody({ items: [{ menuItemId: 'ampesi', quantity: 1 }] }),
      );

      expect(res.status).toBe(409);
      expect(res.body.error).toEqual({
        code: 'conflict',
        message: 'Ampesi is not available right now.',
      });
    });

    it('rejects an order from a closed restaurant with 409', async () => {
      const res = await placeOrder(
        'ama',
        orderBody({ restaurantId: 'closed', items: [{ menuItemId: 'jollof', quantity: 1 }] }),
      );

      expect(res.status).toBe(409);
      expect(res.body.error.code).toBe('conflict');
    });

    it('rejects an item that is not on the menu with 400', async () => {
      const res = await placeOrder(
        'ama',
        orderBody({ items: [{ menuItemId: 'pizza', quantity: 1 }] }),
      );

      expect(res.status).toBe(400);
      expect(res.body.error.code).toBe('validation_error');
    });

    it('returns 404 for an unknown restaurant', async () => {
      const res = await placeOrder('ama', orderBody({ restaurantId: 'nope' }));

      expect(res.status).toBe(404);
    });

    it.each([
      ['quantity 0', { items: [{ menuItemId: 'jollof', quantity: 0 }] }],
      ['quantity 21', { items: [{ menuItemId: 'jollof', quantity: 21 }] }],
      ['no items', { items: [] }],
      [
        '31 line items',
        { items: Array.from({ length: 31 }, () => ({ menuItemId: 'jollof', quantity: 1 })) },
      ],
      ['unknown payment method', { paymentMethod: 'momo' }],
      ['missing address', { deliveryAddress: undefined }],
    ])('rejects %s with 400', async (_name, overrides) => {
      const res = await placeOrder('ama', orderBody(overrides));

      expect(res.status).toBe(400);
      expect(res.body.error.code).toBe('validation_error');
    });

    it('requires authentication', async () => {
      const res = await request(app).post('/v1/orders').send(orderBody());

      expect(res.status).toBe(401);
      expect(res.body.error.code).toBe('unauthorized');
    });
  });

  describe('GET /v1/orders', () => {
    it("lists only the caller's orders, newest first", async () => {
      const first = await placeOrder('ama');
      await placeOrder('kofi');
      const second = await placeOrder('ama');

      const res = await request(app).get('/v1/orders').set(bearer('ama'));

      expect(res.status).toBe(200);
      expect(res.body.items.map((o) => o.id)).toEqual([second.body.id, first.body.id]);
    });
  });

  describe('GET /v1/orders/:id', () => {
    it('returns the order to its owner', async () => {
      const placed = await placeOrder('ama');

      const res = await request(app).get(`/v1/orders/${placed.body.id}`).set(bearer('ama'));

      expect(res.status).toBe(200);
      expect(res.body.id).toBe(placed.body.id);
    });

    it('is forbidden for another user', async () => {
      const placed = await placeOrder('ama');

      const res = await request(app).get(`/v1/orders/${placed.body.id}`).set(bearer('kofi'));

      expect(res.status).toBe(403);
      expect(res.body.error.code).toBe('forbidden');
    });

    it('returns 404 for an unknown order', async () => {
      const res = await request(app).get('/v1/orders/missing').set(bearer('ama'));

      expect(res.status).toBe(404);
    });
  });

  describe('POST /v1/orders/:id/cancel', () => {
    it('cancels an order that is still placed', async () => {
      const placed = await placeOrder('ama');

      const res = await request(app)
        .post(`/v1/orders/${placed.body.id}/cancel`)
        .set(bearer('ama'));

      expect(res.status).toBe(200);
      expect(res.body.status).toBe('cancelled');
      expect(res.body.statusHistory.map((h) => h.status)).toEqual(['placed', 'cancelled']);
    });

    it('returns 409 once the order has been accepted', async () => {
      const placed = await placeOrder('ama');
      await db
        .collection(COLLECTIONS.orders)
        .doc(placed.body.id)
        .update({ status: 'accepted' });

      const res = await request(app)
        .post(`/v1/orders/${placed.body.id}/cancel`)
        .set(bearer('ama'));

      expect(res.status).toBe(409);
      expect(res.body.error.code).toBe('conflict');
    });

    it("cannot cancel someone else's order", async () => {
      const placed = await placeOrder('ama');

      const res = await request(app)
        .post(`/v1/orders/${placed.body.id}/cancel`)
        .set(bearer('kofi'));

      expect(res.status).toBe(403);
    });
  });

  describe('POST /v1/orders/:id/advance', () => {
    it('is not mounted unless demo endpoints are enabled', async () => {
      const placed = await placeOrder('ama');

      const res = await request(app)
        .post(`/v1/orders/${placed.body.id}/advance`)
        .set(bearer('ama'));

      expect(res.status).toBe(404);
    });

    it('walks an order through every status, then returns 409', async () => {
      ({ app, db } = buildTestApp({ env: { ENABLE_DEMO_ENDPOINTS: 'true' } }));
      await addRestaurant(db, 'adwoa');
      await addMenuItem(db, 'adwoa', 'jollof');
      await addMenuItem(db, 'adwoa', 'sobolo');
      const placed = await placeOrder('ama');
      const advance = () =>
        request(app).post(`/v1/orders/${placed.body.id}/advance`).set(bearer('ama'));

      const statuses = [];
      for (let step = 0; step < 4; step += 1) {
        statuses.push((await advance()).body.status);
      }
      const finished = await advance();

      expect(statuses).toEqual(['accepted', 'preparing', 'on_the_way', 'delivered']);
      expect(finished.status).toBe(409);
    });
  });
});

describe('PUT /v1/me/device-token', () => {
  it('stores the token on the user document without duplicates', async () => {
    const { app, db } = buildTestApp();
    const put = (token) =>
      request(app).put('/v1/me/device-token').set(bearer('ama')).send({ token });

    expect((await put('token-a')).status).toBe(204);
    await put('token-b');
    await put('token-a');

    const user = await db.collection(COLLECTIONS.users).doc('ama').get();
    expect(user.data().fcmTokens).toEqual(['token-b', 'token-a']);
  });

  it('rejects an empty token', async () => {
    const { app } = buildTestApp();

    const res = await request(app)
      .put('/v1/me/device-token')
      .set(bearer('ama'))
      .send({ token: '' });

    expect(res.status).toBe(400);
  });

  it('requires authentication', async () => {
    const { app } = buildTestApp();

    const res = await request(app).put('/v1/me/device-token').send({ token: 'x' });

    expect(res.status).toBe(401);
  });
});
