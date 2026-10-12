import { z } from 'zod';

/** Firestore document ids: non-empty, no slashes, reasonable length. */
export const documentId = z
  .string()
  .min(1)
  .max(128)
  .regex(/^[^/]+$/, 'must not contain "/"');

export const idParams = z.object({ id: documentId });
