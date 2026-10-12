import { z } from 'zod';

export const deviceTokenBody = z.object({
  token: z.string().trim().min(1).max(4096),
});
