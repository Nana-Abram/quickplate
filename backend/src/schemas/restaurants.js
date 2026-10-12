import { z } from 'zod';

import { documentId } from './common.js';

export const listRestaurantsQuery = z.object({
  q: z
    .string()
    .trim()
    .max(50)
    .optional()
    .transform((value) => value || undefined),
  category: z.string().trim().min(1).max(40).optional(),
  limit: z.coerce.number().int().min(1).max(30).default(10),
  cursor: documentId.optional(),
});
