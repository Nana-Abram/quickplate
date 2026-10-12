import { COLLECTIONS } from '../utils/collections.js';
import { HttpError } from '../utils/errors.js';
import { toIsoString } from '../utils/serialize.js';

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

export function createRestaurantService({ db }) {
  const restaurants = () => db.collection(COLLECTIONS.restaurants);

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
  async function list({ q, category, limit, cursor }) {
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

  async function getById(id) {
    return toRestaurant(await getRestaurantDoc(id));
  }

  /** Returns the menu grouped by category, in the restaurant's menu order. */
  async function getMenu(id) {
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
