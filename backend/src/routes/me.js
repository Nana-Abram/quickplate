import { Router } from 'express';

import { validate } from '../middleware/validate.js';
import { deviceTokenBody } from '../schemas/me.js';

export function meRouter({ userService }) {
  const router = Router();

  router.put('/device-token', validate({ body: deviceTokenBody }), async (req, res) => {
    await userService.registerDeviceToken(req.user, req.valid.body.token);
    res.status(204).end();
  });

  return router;
}
