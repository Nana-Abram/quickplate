import { createApp } from '../../src/app.js';
import { createServices } from '../../src/services/index.js';
import { silentLogger } from '../../src/utils/logger.js';
import { createFakeAuth } from './fakeAuth.js';
import { createFakeFirestore } from './fakeFirestore.js';
import { createFakeMessaging } from './fakeMessaging.js';
import { testConfig } from './testConfig.js';

/** Builds the real app and services on top of in-memory Firebase fakes. */
export function buildTestApp({ env = {} } = {}) {
  const config = testConfig(env);
  const db = createFakeFirestore();
  const auth = createFakeAuth();
  const messaging = createFakeMessaging();
  const services = createServices({ db, messaging, config, logger: silentLogger });
  const app = createApp({ config, auth, services, logger: silentLogger });

  return { app, db, messaging, services };
}
