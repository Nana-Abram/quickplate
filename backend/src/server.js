import 'dotenv/config';

import { createApp } from './app.js';
import { loadConfig } from './config.js';
import { initFirebase } from './firebase.js';
import { createServices } from './services/index.js';
import { consoleLogger as logger } from './utils/logger.js';

const config = loadConfig();
const firebase = initFirebase(config);
const services = createServices({ ...firebase, config, logger });
const app = createApp({ config, auth: firebase.auth, services, logger });

const server = app.listen(config.port, () => {
  logger.info(`QuickPlate API listening on http://localhost:${config.port}/v1`);
  if (config.enableDemoEndpoints) logger.info('Demo endpoints enabled.');
});

function shutdown(signal) {
  logger.info(`${signal} received, shutting down.`);
  services.simulator.stopAll();
  server.close(() => process.exit(0));
}

process.on('SIGTERM', shutdown);
process.on('SIGINT', shutdown);
