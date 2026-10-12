import { z } from 'zod';

import { PAYMENT_METHODS } from '../utils/orderStatus.js';
import { documentId } from './common.js';

// z.object strips unknown keys, so any price a client sends is dropped here
// and never reaches the order service.
const orderItem = z.object({
  menuItemId: documentId,
  quantity: z.number().int().min(1).max(20),
  notes: z.string().trim().max(200).default(''),
});

const deliveryAddress = z.object({
  label: z.string().trim().min(1).max(40),
  line1: z.string().trim().min(1).max(200),
  lat: z.number().min(-90).max(90),
  lng: z.number().min(-180).max(180),
});

export const createOrderBody = z.object({
  restaurantId: documentId,
  items: z.array(orderItem).min(1).max(30),
  deliveryAddress,
  paymentMethod: z.enum(PAYMENT_METHODS),
});
