export const ORDER_STATUS = Object.freeze({
  placed: 'placed',
  accepted: 'accepted',
  preparing: 'preparing',
  onTheWay: 'on_the_way',
  delivered: 'delivered',
  cancelled: 'cancelled',
});

export const PAYMENT_METHODS = Object.freeze(['cash_on_delivery', 'mock_card']);

const FLOW = [
  ORDER_STATUS.placed,
  ORDER_STATUS.accepted,
  ORDER_STATUS.preparing,
  ORDER_STATUS.onTheWay,
  ORDER_STATUS.delivered,
];

/** The status after `status` in the delivery flow, or null if there is none. */
export function nextStatus(status) {
  const index = FLOW.indexOf(status);
  return index >= 0 && index < FLOW.length - 1 ? FLOW[index + 1] : null;
}
