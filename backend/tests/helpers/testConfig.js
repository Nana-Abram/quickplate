import { loadConfig } from '../../src/config.js';

export function testConfig(overrides = {}) {
  return loadConfig({
    NODE_ENV: 'test',
    SIM_STEP_SECONDS: '0',
    RATE_LIMIT_PER_MINUTE: '1000',
    ...overrides,
  });
}
