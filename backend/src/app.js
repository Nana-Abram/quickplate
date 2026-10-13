import cors from 'cors';
import express from 'express';
import helmet from 'helmet';

import { requireAuth } from './middleware/auth.js';
import { errorHandler, notFoundHandler } from './middleware/error.js';
import { rateLimit } from './middleware/rateLimit.js';
import { healthRouter } from './routes/health.js';
import { meRouter } from './routes/me.js';
import { ordersRouter } from './routes/orders.js';
import { restaurantsRouter } from './routes/restaurants.js';
import { consoleLogger } from './utils/logger.js';

/**
 * Builds the Express app. Everything that touches the outside world is passed
 * in, so tests can run the real routes against in-memory fakes.
 */
export function createApp({ config, auth, services, logger = consoleLogger }) {
  const app = express();

  app.disable('x-powered-by');
  if (config.trustProxyHops > 0) app.set('trust proxy', config.trustProxyHops);
  app.use(helmet());
  app.use(
    cors({ origin: config.corsOrigins.includes('*') ? '*' : config.corsOrigins }),
  );
  app.use(rateLimit({ limit: config.rateLimitPerMinute }));
  app.use(express.json({ limit: '100kb' }));

  const v1 = express.Router();
  const authenticated = requireAuth(auth);
  v1.use(healthRouter());
  v1.use(
    '/restaurants',
    restaurantsRouter({ ...services, cacheSeconds: config.restaurantCacheSeconds }),
  );
  v1.use(
    '/orders',
    authenticated,
    ordersRouter({ ...services, enableDemoEndpoints: config.enableDemoEndpoints }),
  );
  v1.use('/me', authenticated, meRouter(services));

  app.use('/v1', v1);
  app.use(notFoundHandler);
  app.use(errorHandler(logger));

  return app;
}
