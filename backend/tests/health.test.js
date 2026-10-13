import request from 'supertest';
import { describe, expect, it } from 'vitest';

import { buildTestApp } from './helpers/testApp.js';
import { testConfig } from './helpers/testConfig.js';

describe('app basics', () => {
  it('GET /v1/health returns ok', async () => {
    const { app } = buildTestApp();

    const res = await request(app).get('/v1/health');

    expect(res.status).toBe(200);
    expect(res.body).toEqual({ status: 'ok' });
  });

  it('unknown routes return the not_found error shape', async () => {
    const { app } = buildTestApp();

    const res = await request(app).get('/v1/nope');

    expect(res.status).toBe(404);
    expect(res.body.error.code).toBe('not_found');
  });

  it('rejects requests over the rate limit with 429', async () => {
    const { app } = buildTestApp({ env: { RATE_LIMIT_PER_MINUTE: '2' } });

    await request(app).get('/v1/health');
    await request(app).get('/v1/health');
    const res = await request(app).get('/v1/health');

    expect(res.status).toBe(429);
    expect(res.body.error.code).toBe('rate_limited');
  });
});

describe('behind a proxy', () => {
  async function secondRequestFromAnotherClient(env) {
    const { app } = buildTestApp({ env: { RATE_LIMIT_PER_MINUTE: '1', ...env } });
    await request(app).get('/v1/health').set('X-Forwarded-For', '203.0.113.1');
    return request(app).get('/v1/health').set('X-Forwarded-For', '203.0.113.2');
  }

  it('rate limits each client separately when the proxy is trusted', async () => {
    const res = await secondRequestFromAnotherClient({ TRUST_PROXY_HOPS: '1' });

    expect(res.status).toBe(200);
  });

  it('ignores X-Forwarded-For when no proxy is trusted', async () => {
    const res = await secondRequestFromAnotherClient({});

    expect(res.status).toBe(429);
  });
});

describe('loadConfig', () => {
  it('applies defaults', () => {
    const config = testConfig();

    expect(config.port).toBe(4000);
    expect(config.enableDemoEndpoints).toBe(false);
    expect(config.corsOrigins).toEqual(['*']);
  });

  it('throws on invalid values', () => {
    expect(() => testConfig({ SIM_STEP_SECONDS: 'soon' })).toThrow(/SIM_STEP_SECONDS/);
  });
});
