import { COLLECTIONS } from '../../src/utils/collections.js';

export async function addRestaurant(db, id, overrides = {}) {
  const name = overrides.name ?? `Restaurant ${id}`;
  await db
    .collection(COLLECTIONS.restaurants)
    .doc(id)
    .set({
      name,
      nameLower: name.toLowerCase(),
      description: 'Test restaurant',
      imageUrl: 'https://example.com/r.jpg',
      categories: ['Local'],
      rating: 4.5,
      deliveryFeePesewas: 1000,
      etaMinutes: 30,
      isOpen: true,
      location: { lat: 6.69, lng: -1.62 },
      createdAt: new Date('2026-01-01T00:00:00Z'),
      ...overrides,
    });
}

export async function addMenuItem(db, restaurantId, id, overrides = {}) {
  await db
    .collection(COLLECTIONS.restaurants)
    .doc(restaurantId)
    .collection(COLLECTIONS.menuItems)
    .doc(id)
    .set({
      name: `Item ${id}`,
      description: 'Test item',
      imageUrl: 'https://example.com/i.jpg',
      category: 'Mains',
      pricePesewas: 2500,
      isAvailable: true,
      sortOrder: 0,
      ...overrides,
    });
}
