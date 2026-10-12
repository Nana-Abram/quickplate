import { createRestaurantService } from './restaurantService.js';

/** Builds every service from the Firebase clients and config. */
export function createServices({ db }) {
  return {
    restaurantService: createRestaurantService({ db }),
  };
}
