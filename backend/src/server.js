import 'dotenv/config';

import { createApp } from './app.js';
import { loadConfig } from './config.js';
import { initFirebase } from './firebase.js';
import { createServices } from './services/index.js';
import { consoleLogger as logger } from './utils/logger.js';

const config = loadConfig();
const firebase = initFirebase(config);
const services = createServices({ ...firebase, config, logger });
const app = createApp({ config, services, logger });

app.listen(config.port, () => {
  logger.info(`QuickPlate API listening on http://localhost:${config.port}/v1`);
});
