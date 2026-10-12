import express from 'express';
import request from 'supertest';
import { describe, expect, it } from 'vitest';

import { requireAuth } from '../src/middleware/auth.js';
import { errorHandler } from '../src/middleware/error.js';
import { silentLogger } from '../src/utils/logger.js';
import { bearer, createFakeAuth } from './helpers/fakeAuth.js';

function appWithProtectedRoute() {
  const app = express();
  app.get('/private', requireAuth(createFakeAuth()), (req, res) => {
    res.json({ uid: req.user.uid });
  });
  app.use(errorHandler(silentLogger));
  return app;
}

describe('requireAuth', () => {
  it('rejects a request without a token', async () => {
    const res = await request(appWithProtectedRoute()).get('/private');

    expect(res.status).toBe(401);
    expect(res.body.error.code).toBe('unauthorized');
  });

  it('rejects an invalid token', async () => {
    const res = await request(appWithProtectedRoute())
      .get('/private')
      .set('Authorization', 'Bearer garbage');

    expect(res.status).toBe(401);
  });

  it('exposes the verified uid', async () => {
    const res = await request(appWithProtectedRoute()).get('/private').set(bearer('ama'));

    expect(res.status).toBe(200);
    expect(res.body).toEqual({ uid: 'ama' });
  });
});
