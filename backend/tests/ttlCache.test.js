import { describe, expect, it, vi } from 'vitest';

import { createTtlCache } from '../src/utils/ttlCache.js';

describe('createTtlCache', () => {
  function setup(ttlMs = 1000) {
    let time = 0;
    const cache = createTtlCache({ ttlMs, now: () => time });
    return { cache, advance: (ms) => (time += ms) };
  }

  it('reuses a value until it expires', async () => {
    const { cache, advance } = setup();
    const load = vi.fn(async () => 'menu');

    await cache.get('k', load);
    advance(999);
    await cache.get('k', load);
    expect(load).toHaveBeenCalledTimes(1);

    advance(1);
    await cache.get('k', load);
    expect(load).toHaveBeenCalledTimes(2);
  });

  it('shares one load between concurrent misses', async () => {
    const { cache } = setup();
    const load = vi.fn(async () => 'menu');

    const results = await Promise.all([cache.get('k', load), cache.get('k', load)]);

    expect(results).toEqual(['menu', 'menu']);
    expect(load).toHaveBeenCalledTimes(1);
  });

  it('does not keep failures', async () => {
    const { cache } = setup();
    const failing = vi.fn(async () => {
      throw new Error('down');
    });

    await expect(cache.get('k', failing)).rejects.toThrow('down');
    expect(await cache.get('k', async () => 'menu')).toBe('menu');
  });

  it('is off when the ttl is 0', async () => {
    const { cache } = setup(0);
    const load = vi.fn(async () => 'menu');

    await cache.get('k', load);
    await cache.get('k', load);

    expect(load).toHaveBeenCalledTimes(2);
  });
});
