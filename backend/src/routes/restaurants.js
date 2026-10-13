import { Router } from 'express';

import { validate } from '../middleware/validate.js';
import { idParams } from '../schemas/common.js';
import { listRestaurantsQuery } from '../schemas/restaurants.js';

export function restaurantsRouter({ restaurantService, cacheSeconds = 0 }) {
  const router = Router();

  // Restaurants and menus are public and change rarely, so clients and
  // proxies may reuse them briefly. Order prices are always re-read.
  if (cacheSeconds > 0) {
    router.use((_req, res, next) => {
      res.set('Cache-Control', `public, max-age=${cacheSeconds}`);
      next();
    });
  }

  router.get('/', validate({ query: listRestaurantsQuery }), async (req, res) => {
    res.json(await restaurantService.list(req.valid.query));
  });

  router.get('/:id', validate({ params: idParams }), async (req, res) => {
    res.json(await restaurantService.getById(req.valid.params.id));
  });

  router.get('/:id/menu', validate({ params: idParams }), async (req, res) => {
    res.json(await restaurantService.getMenu(req.valid.params.id));
  });

  return router;
}
