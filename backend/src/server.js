import 'dotenv/config';

import { createApp } from './app.js';
import { loadConfig } from './config.js';
import { consoleLogger as logger } from './utils/logger.js';

const config = loadConfig();
const app = createApp({ config, logger });

app.listen(config.port, () => {
  logger.info(`QuickPlate API listening on http://localhost:${config.port}/v1`);
});
