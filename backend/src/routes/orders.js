import { Router } from 'express';

import { validate } from '../middleware/validate.js';
import { idParams } from '../schemas/common.js';
import { createOrderBody } from '../schemas/orders.js';

export function ordersRouter({ orderService, enableDemoEndpoints }) {
  const router = Router();

  router.post('/', validate({ body: createOrderBody }), async (req, res) => {
    res.status(201).json(await orderService.create(req.user, req.valid.body));
  });

  router.get('/', async (req, res) => {
    res.json(await orderService.listForUser(req.user));
  });

  router.get('/:id', validate({ params: idParams }), async (req, res) => {
    res.json(await orderService.getForUser(req.user, req.valid.params.id));
  });

  router.post('/:id/cancel', validate({ params: idParams }), async (req, res) => {
    res.json(await orderService.cancel(req.user, req.valid.params.id));
  });

  if (enableDemoEndpoints) {
    router.post('/:id/advance', validate({ params: idParams }), async (req, res) => {
      res.json(await orderService.advanceForUser(req.user, req.valid.params.id));
    });
  }

  return router;
}
