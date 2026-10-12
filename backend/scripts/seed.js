import 'dotenv/config';

import { loadConfig } from '../src/config.js';
import { initFirebase } from '../src/firebase.js';
import { COLLECTIONS } from '../src/utils/collections.js';
import { restaurants } from './seedData.js';

/**
 * Writes the sample restaurants and menus. Document ids are slugs of the
 * names, so running it again updates the same documents instead of adding
 * duplicates. Restaurants and menu items no longer in the seed data are
 * removed; past orders keep working because they store the restaurant name.
 */
async function seed() {
  const { db } = initFirebase(loadConfig());
  const now = new Date();

  const seededRestaurantIds = new Set(restaurants.map((r) => r.id));
  const existingRestaurants = await db.collection(COLLECTIONS.restaurants).get();
  for (const doc of existingRestaurants.docs) {
    if (seededRestaurantIds.has(doc.id)) continue;
    await db.recursiveDelete(doc.ref);
    console.log(`Removed ${doc.get('name') ?? doc.id}`);
  }

  for (const { id, menu, ...fields } of restaurants) {
    const restaurantRef = db.collection(COLLECTIONS.restaurants).doc(id);
    const menuRef = restaurantRef.collection(COLLECTIONS.menuItems);
    const batch = db.batch();

    batch.set(restaurantRef, { ...fields, nameLower: fields.name.toLowerCase(), createdAt: now });

    const seededIds = new Set(menu.map((menuItem) => menuItem.id));
    const existing = await menuRef.get();
    for (const doc of existing.docs) {
      if (!seededIds.has(doc.id)) batch.delete(doc.ref);
    }
    for (const { id: itemId, ...itemFields } of menu) {
      batch.set(menuRef.doc(itemId), itemFields);
    }

    await batch.commit();
    console.log(`Seeded ${fields.name} (${menu.length} items)`);
  }

  console.log(`Done: ${restaurants.length} restaurants.`);
}

seed().catch((error) => {
  console.error('Seeding failed:', error.message);
  process.exitCode = 1;
});
