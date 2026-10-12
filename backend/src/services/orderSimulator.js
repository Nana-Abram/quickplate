import { nextStatus } from '../utils/orderStatus.js';

/**
 * Plays the restaurant and rider: advances each new order one status every
 * `stepSeconds`. Timers live only in memory, so after a restart old orders
 * stay where they were instead of jumping ahead.
 */
export function createOrderSimulator({ stepSeconds, advance, logger }) {
  const timers = new Map();
  const enabled = stepSeconds > 0;

  function stop(orderId) {
    clearTimeout(timers.get(orderId));
    timers.delete(orderId);
  }

  function schedule(orderId) {
    const timer = setTimeout(async () => {
      timers.delete(orderId);
      try {
        const order = await advance(orderId);
        if (order && nextStatus(order.status)) schedule(orderId);
      } catch (error) {
        logger.error(`Simulator failed to advance order ${orderId}`, error);
      }
    }, stepSeconds * 1000);

    // Pending steps should not keep the process alive on shutdown.
    timer.unref?.();
    timers.set(orderId, timer);
  }

  return {
    start(orderId) {
      if (!enabled) return;
      stop(orderId);
      schedule(orderId);
    },
    stop,
    stopAll() {
      for (const orderId of [...timers.keys()]) stop(orderId);
    },
    get activeCount() {
      return timers.size;
    },
  };
}
