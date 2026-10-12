import request from 'supertest';
import { beforeEach, describe, expect, it } from 'vitest';

import { addMenuItem, addRestaurant } from './helpers/fixtures.js';
import { buildTestApp } from './helpers/testApp.js';

describe('restaurants', () => {
  let app;
  let db;

  beforeEach(async () => {
    ({ app, db } = buildTestApp());
    await addRestaurant(db, 'akwaaba', { name: 'Akwaaba Kitchen', categories: ['Local'] });
    await addRestaurant(db, 'burger-hub', { name: 'Burger Hub', categories: ['Fast Food'] });
    await addRestaurant(db, 'bowl-bar', { name: 'Bowl Bar', categories: ['Healthy'] });
    await addRestaurant(db, 'chop-bar', { name: 'Chop Bar', categories: ['Local'] });
  });

  describe('GET /v1/restaurants', () => {
    it('lists restaurants by name with internal fields stripped', async () => {
      const res = await request(app).get('/v1/restaurants');

      expect(res.status).toBe(200);
      expect(res.body.items.map((r) => r.name)).toEqual([
        'Akwaaba Kitchen',
        'Bowl Bar',
        'Burger Hub',
        'Chop Bar',
      ]);
      expect(res.body.items[0]).not.toHaveProperty('nameLower');
      expect(res.body.items[0].createdAt).toBe('2026-01-01T00:00:00.000Z');
      expect(res.body.nextCursor).toBeNull();
    });

    it('pages with a cursor', async () => {
      const first = await request(app).get('/v1/restaurants?limit=3');
      expect(first.body.items).toHaveLength(3);
      expect(first.body.nextCursor).toBe('burger-hub');

      const second = await request(app).get(
        `/v1/restaurants?limit=3&cursor=${first.body.nextCursor}`,
      );
      expect(second.body.items.map((r) => r.id)).toEqual(['chop-bar']);
      expect(second.body.nextCursor).toBeNull();
    });

    it('filters by category', async () => {
      const res = await request(app).get('/v1/restaurants?category=Local');

      expect(res.body.items.map((r) => r.id)).toEqual(['akwaaba', 'chop-bar']);
    });

    it('searches by case-insensitive name prefix', async () => {
      const res = await request(app).get('/v1/restaurants?q=BU');

      expect(res.body.items.map((r) => r.id)).toEqual(['burger-hub']);
    });

    it('rejects a limit above 30', async () => {
      const res = await request(app).get('/v1/restaurants?limit=31');

      expect(res.status).toBe(400);
      expect(res.body.error.code).toBe('validation_error');
    });

    it('rejects an unknown cursor', async () => {
      const res = await request(app).get('/v1/restaurants?cursor=missing');

      expect(res.status).toBe(400);
    });
  });

  describe('GET /v1/restaurants/:id', () => {
    it('returns one restaurant', async () => {
      const res = await request(app).get('/v1/restaurants/akwaaba');

      expect(res.status).toBe(200);
      expect(res.body.name).toBe('Akwaaba Kitchen');
    });

    it('returns 404 for an unknown id', async () => {
      const res = await request(app).get('/v1/restaurants/nope');

      expect(res.status).toBe(404);
      expect(res.body.error.code).toBe('not_found');
    });
  });

  describe('GET /v1/restaurants/:id/menu', () => {
    it('groups items by category in menu order', async () => {
      await addMenuItem(db, 'akwaaba', 'drink', { category: 'Drinks', sortOrder: 2 });
      await addMenuItem(db, 'akwaaba', 'jollof', { category: 'Mains', sortOrder: 0 });
      await addMenuItem(db, 'akwaaba', 'waakye', { category: 'Mains', sortOrder: 1 });

      const res = await request(app).get('/v1/restaurants/akwaaba/menu');

      expect(res.status).toBe(200);
      expect(res.body.categories.map((c) => c.name)).toEqual(['Mains', 'Drinks']);
      expect(res.body.categories[0].items.map((i) => i.id)).toEqual(['jollof', 'waakye']);
      expect(res.body.categories[0].items[0]).not.toHaveProperty('sortOrder');
    });

    it('returns 404 for an unknown restaurant', async () => {
      const res = await request(app).get('/v1/restaurants/nope/menu');

      expect(res.status).toBe(404);
    });
  });
});
