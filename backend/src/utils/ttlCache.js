/**
 * A small in-memory cache whose entries expire after `ttlMs`. A ttl of 0
 * turns it off. Concurrent misses for the same key share one load, so a
 * burst of requests costs a single Firestore read. Failed loads are not
 * cached.
 */
export function createTtlCache({ ttlMs, now = Date.now, maxEntries = 500 }) {
  const entries = new Map();

  async function get(key, load) {
    if (ttlMs <= 0) return load();

    const hit = entries.get(key);
    if (hit && now() < hit.expiresAt) return hit.value;

    const value = load();
    entries.set(key, { value, expiresAt: now() + ttlMs });
    if (entries.size > maxEntries) entries.delete(entries.keys().next().value);
    try {
      return await value;
    } catch (error) {
      entries.delete(key);
      throw error;
    }
  }

  return { get, clear: () => entries.clear() };
}
