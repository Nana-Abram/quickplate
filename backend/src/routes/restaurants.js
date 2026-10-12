import { Router } from 'express';

import { validate } from '../middleware/validate.js';
import { idParams } from '../schemas/common.js';
import { listRestaurantsQuery } from '../schemas/restaurants.js';

export function restaurantsRouter({ restaurantService }) {
  const router = Router();

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
