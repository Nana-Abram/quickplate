import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';

import { createOrderSimulator } from '../src/services/orderSimulator.js';
import { nextStatus } from '../src/utils/orderStatus.js';
import { silentLogger } from '../src/utils/logger.js';

describe('orderSimulator', () => {
  let statuses;
  const advance = vi.fn(async (orderId) => {
    const next = nextStatus(statuses[orderId]);
    if (!next) return null;
    statuses[orderId] = next;
    return { id: orderId, status: next };
  });

  beforeEach(() => {
    vi.useFakeTimers();
    statuses = { a: 'placed' };
    advance.mockClear();
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  it('advances one step per interval until delivered, then stops', async () => {
    const simulator = createOrderSimulator({ stepSeconds: 20, advance, logger: silentLogger });

    simulator.start('a');
    await vi.advanceTimersByTimeAsync(19_999);
    expect(statuses.a).toBe('placed');

    await vi.advanceTimersByTimeAsync(1);
    expect(statuses.a).toBe('accepted');

    await vi.advanceTimersByTimeAsync(60_000);
    expect(statuses.a).toBe('delivered');
    expect(simulator.activeCount).toBe(0);
    expect(advance).toHaveBeenCalledTimes(4);
  });

  it('stops advancing a stopped order', async () => {
    const simulator = createOrderSimulator({ stepSeconds: 20, advance, logger: silentLogger });

    simulator.start('a');
    simulator.stop('a');
    await vi.advanceTimersByTimeAsync(100_000);

    expect(advance).not.toHaveBeenCalled();
  });

  it('does nothing when the step is 0', async () => {
    const simulator = createOrderSimulator({ stepSeconds: 0, advance, logger: silentLogger });

    simulator.start('a');
    await vi.advanceTimersByTimeAsync(100_000);

    expect(advance).not.toHaveBeenCalled();
    expect(simulator.activeCount).toBe(0);
  });

  it('logs and stops when advancing fails', async () => {
    const logger = { ...silentLogger, error: vi.fn() };
    const failing = vi.fn().mockRejectedValue(new Error('firestore down'));
    const simulator = createOrderSimulator({ stepSeconds: 1, advance: failing, logger });

    simulator.start('a');
    await vi.advanceTimersByTimeAsync(5_000);

    expect(failing).toHaveBeenCalledTimes(1);
    expect(logger.error).toHaveBeenCalled();
  });
});
