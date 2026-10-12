import cors from 'cors';
import express from 'express';
import helmet from 'helmet';

import { errorHandler, notFoundHandler } from './middleware/error.js';
import { rateLimit } from './middleware/rateLimit.js';
import { healthRouter } from './routes/health.js';
import { consoleLogger } from './utils/logger.js';

/**
 * Builds the Express app. Everything that touches the outside world is passed
 * in, so tests can run the real routes against in-memory fakes.
 */
export function createApp({ config, logger = consoleLogger }) {
  const app = express();

  app.disable('x-powered-by');
  app.use(helmet());
  app.use(
    cors({ origin: config.corsOrigins.includes('*') ? '*' : config.corsOrigins }),
  );
  app.use(rateLimit({ limit: config.rateLimitPerMinute }));
  app.use(express.json({ limit: '100kb' }));

  const v1 = express.Router();
  v1.use(healthRouter());

  app.use('/v1', v1);
  app.use(notFoundHandler);
  app.use(errorHandler(logger));

  return app;
}
