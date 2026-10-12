import { HttpError } from '../utils/errors.js';

const WINDOW_MS = 60_000;

/**
 * Fixed-window, per-IP rate limit kept in memory. Good enough for a single
 * instance demo API; a multi-instance deploy would need a shared store.
 */
export function rateLimit({ limit, now = Date.now }) {
  const hits = new Map();

  return (req, res, next) => {
    const currentTime = now();
    const key = req.ip ?? 'unknown';
    let entry = hits.get(key);

    if (!entry || currentTime >= entry.resetAt) {
      entry = { count: 0, resetAt: currentTime + WINDOW_MS };
      hits.set(key, entry);
    }

    entry.count += 1;
    res.setHeader('RateLimit-Limit', String(limit));
    res.setHeader('RateLimit-Remaining', String(Math.max(0, limit - entry.count)));

    if (entry.count > limit) {
      res.setHeader('Retry-After', String(Math.ceil((entry.resetAt - currentTime) / 1000)));
      next(HttpError.tooManyRequests());
      return;
    }

    // Drop expired entries now and then so the map cannot grow without bound.
    if (hits.size > 10_000) {
      for (const [ip, value] of hits) {
        if (currentTime >= value.resetAt) hits.delete(ip);
      }
    }

    next();
  };
}
