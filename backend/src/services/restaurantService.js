import { COLLECTIONS } from '../utils/collections.js';
import { HttpError } from '../utils/errors.js';
import { toIsoString } from '../utils/serialize.js';
import { createTtlCache } from '../utils/ttlCache.js';

// The highest code point Firestore sorts, used as an upper bound for prefix ranges.
const PREFIX_END = '';

function toRestaurant(doc) {
  const data = doc.data();
  return {
    id: doc.id,
    name: data.name,
    description: data.description,
    imageUrl: data.imageUrl,
    categories: data.categories ?? [],
    rating: data.rating,
    deliveryFeePesewas: data.deliveryFeePesewas,
    etaMinutes: data.etaMinutes,
    isOpen: data.isOpen,
    location: data.location,
    createdAt: toIsoString(data.createdAt),
  };
}

function toMenuItem(doc) {
  const data = doc.data();
  return {
    id: doc.id,
    name: data.name,
    description: data.description,
    imageUrl: data.imageUrl,
    category: data.category,
    pricePesewas: data.pricePesewas,
    isAvailable: data.isAvailable,
  };
}

/**
 * Reads are cached in memory for `cacheSeconds`, so popular pages and menus
 * do not cost a Firestore read per request. Seeding shows up once entries
 * expire. Orders never use this cache: prices are read fresh when ordering.
 */
export function createRestaurantService({ db, cacheSeconds = 0, now = Date.now }) {
  const restaurants = () => db.collection(COLLECTIONS.restaurants);
  const cache = createTtlCache({ ttlMs: cacheSeconds * 1000, now });

  async function getRestaurantDoc(id) {
    const doc = await restaurants().doc(id).get();
    if (!doc.exists) throw HttpError.notFound('Restaurant not found.');
    return doc;
  }

  /**
   * Lists restaurants by name, optionally filtered by category and a
   * case-insensitive name prefix. `cursor` is the id of the last restaurant on
   * the previous page.
   */
  function list(params) {
    const { q, category, limit, cursor } = params;
    return cache.get(`list:${JSON.stringify([q, category, limit, cursor])}`, () =>
      listUncached({ q, category, limit, cursor }),
    );
  }

  async function listUncached({ q, category, limit, cursor }) {
    let query = restaurants();
    if (category) {
      query = query.where('categories', 'array-contains', category);
    }
    if (q) {
      const prefix = q.toLowerCase();
      query = query.where('nameLower', '>=', prefix).where('nameLower', '<=', prefix + PREFIX_END);
    }
    query = query.orderBy('nameLower');

    if (cursor) {
      const cursorDoc = await restaurants().doc(cursor).get();
      if (!cursorDoc.exists) throw HttpError.validation('cursor: unknown cursor.');
      query = query.startAfter(cursorDoc);
    }

    // Fetch one extra document to know whether another page exists.
    const snapshot = await query.limit(limit + 1).get();
    const page = snapshot.docs.slice(0, limit);
    const hasMore = snapshot.docs.length > limit;

    return {
      items: page.map(toRestaurant),
      nextCursor: hasMore ? page.at(-1).id : null,
    };
  }

  function getById(id) {
    return cache.get(`restaurant:${id}`, async () => toRestaurant(await getRestaurantDoc(id)));
  }

  /** Returns the menu grouped by category, in the restaurant's menu order. */
  function getMenu(id) {
    return cache.get(`menu:${id}`, () => getMenuUncached(id));
  }

  async function getMenuUncached(id) {
    const restaurantDoc = await getRestaurantDoc(id);
    const snapshot = await restaurantDoc.ref
      .collection(COLLECTIONS.menuItems)
      .orderBy('sortOrder')
      .get();

    const groups = new Map();
    for (const doc of snapshot.docs) {
      const menuItem = toMenuItem(doc);
      if (!groups.has(menuItem.category)) groups.set(menuItem.category, []);
      groups.get(menuItem.category).push(menuItem);
    }

    return {
      categories: [...groups].map(([name, items]) => ({ name, items })),
    };
  }

  return { list, getById, getMenu };
}
