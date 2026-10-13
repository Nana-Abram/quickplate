import { createNotificationService } from './notificationService.js';
import { createOrderService } from './orderService.js';
import { createOrderSimulator } from './orderSimulator.js';
import { createRestaurantService } from './restaurantService.js';
import { createUserService } from './userService.js';

/** Builds every service from the Firebase clients and config. */
export function createServices({ db, messaging, config, logger }) {
  const notificationService = createNotificationService({ db, messaging, logger });

  // The simulator calls back into the order service, which is created below;
  // the callback only runs after a timer fires, by which point it exists.
  const simulator = createOrderSimulator({
    stepSeconds: config.simStepSeconds,
    advance: (orderId) => orderService.advanceStatus(orderId),
    logger,
  });
  const orderService = createOrderService({ db, simulator, notificationService });

  return {
    restaurantService: createRestaurantService({
      db,
      cacheSeconds: config.restaurantCacheSeconds,
    }),
    orderService,
    userService: createUserService({ db }),
    notificationService,
    simulator,
  };
}
