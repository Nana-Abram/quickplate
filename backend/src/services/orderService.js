import { COLLECTIONS } from '../utils/collections.js';
import { HttpError } from '../utils/errors.js';
import { nextStatus, ORDER_STATUS } from '../utils/orderStatus.js';
import { toIsoString } from '../utils/serialize.js';

const HISTORY_LIMIT = 50;

function toOrder(id, data) {
  return {
    id,
    userId: data.userId,
    restaurantId: data.restaurantId,
    restaurantName: data.restaurantName,
    items: data.items,
    subtotalPesewas: data.subtotalPesewas,
    deliveryFeePesewas: data.deliveryFeePesewas,
    totalPesewas: data.totalPesewas,
    deliveryAddress: data.deliveryAddress,
    paymentMethod: data.paymentMethod,
    status: data.status,
    statusHistory: (data.statusHistory ?? []).map((entry) => ({
      status: entry.status,
      at: toIsoString(entry.at),
    })),
    createdAt: toIsoString(data.createdAt),
    updatedAt: toIsoString(data.updatedAt),
  };
}

export function createOrderService({
  db,
  simulator,
  notificationService,
  now = () => new Date(),
}) {
  const orders = () => db.collection(COLLECTIONS.orders);

  /**
   * Prices every line from Firestore. The request schema has already dropped
   * any client-sent prices, so totals can only come from the menu.
   */
  async function priceItems(restaurantRef, requestedItems) {
    const uniqueIds = [...new Set(requestedItems.map((line) => line.menuItemId))];
    const menuRefs = uniqueIds.map((id) => restaurantRef.collection(COLLECTIONS.menuItems).doc(id));
    const menuDocs = await db.getAll(...menuRefs);
    const menuById = new Map(menuDocs.filter((doc) => doc.exists).map((doc) => [doc.id, doc.data()]));

    return requestedItems.map((line) => {
      const menuItem = menuById.get(line.menuItemId);
      if (!menuItem) {
        throw HttpError.validation(`items: "${line.menuItemId}" is not on this restaurant's menu.`);
      }
      if (!menuItem.isAvailable) {
        throw HttpError.conflict(`${menuItem.name} is not available right now.`);
      }
      return {
        menuItemId: line.menuItemId,
        name: menuItem.name,
        unitPricePesewas: menuItem.pricePesewas,
        quantity: line.quantity,
        notes: line.notes,
      };
    });
  }

  async function create(user, input) {
    const restaurantRef = db.collection(COLLECTIONS.restaurants).doc(input.restaurantId);
    const restaurantDoc = await restaurantRef.get();
    if (!restaurantDoc.exists) throw HttpError.notFound('Restaurant not found.');

    const restaurant = restaurantDoc.data();
    if (!restaurant.isOpen) {
      throw HttpError.conflict(`${restaurant.name} is closed right now.`);
    }

    const items = await priceItems(restaurantRef, input.items);
    const subtotalPesewas = items.reduce(
      (sum, line) => sum + line.unitPricePesewas * line.quantity,
      0,
    );
    const createdAt = now();

    const order = {
      userId: user.uid,
      restaurantId: restaurantDoc.id,
      restaurantName: restaurant.name,
      items,
      subtotalPesewas,
      deliveryFeePesewas: restaurant.deliveryFeePesewas,
      totalPesewas: subtotalPesewas + restaurant.deliveryFeePesewas,
      deliveryAddress: input.deliveryAddress,
      paymentMethod: input.paymentMethod,
      status: ORDER_STATUS.placed,
      statusHistory: [{ status: ORDER_STATUS.placed, at: createdAt }],
      createdAt,
      updatedAt: createdAt,
    };

    const ref = await orders().add(order);
    simulator.start(ref.id);
    return toOrder(ref.id, order);
  }

  async function listForUser(user) {
    const snapshot = await orders()
      .where('userId', '==', user.uid)
      .orderBy('createdAt', 'desc')
      .limit(HISTORY_LIMIT)
      .get();
    return { items: snapshot.docs.map((doc) => toOrder(doc.id, doc.data())) };
  }

  function assertOwner(user, doc) {
    if (!doc.exists) throw HttpError.notFound('Order not found.');
    if (doc.data().userId !== user.uid) throw HttpError.forbidden();
  }

  async function getForUser(user, orderId) {
    const doc = await orders().doc(orderId).get();
    assertOwner(user, doc);
    return toOrder(doc.id, doc.data());
  }

  /**
   * Moves an order to a new status inside a transaction, so a cancel and a
   * simulator step can never both apply. `decide` sees the current data and
   * returns the next status, or null to leave the order unchanged.
   */
  async function transition(orderId, decide) {
    const ref = orders().doc(orderId);

    const updated = await db.runTransaction(async (transaction) => {
      const doc = await transaction.get(ref);
      const status = decide(doc);
      if (!status) return null;

      const changedAt = now();
      const data = doc.data();
      const changes = {
        status,
        statusHistory: [...data.statusHistory, { status, at: changedAt }],
        updatedAt: changedAt,
      };
      transaction.update(ref, changes);
      return toOrder(doc.id, { ...data, ...changes });
    });

    if (updated) {
      // Push delivery is best effort and must not slow down or fail the request.
      void notificationService.notifyStatusChange(updated);
    }
    return updated;
  }

  async function cancel(user, orderId) {
    const order = await transition(orderId, (doc) => {
      assertOwner(user, doc);
      if (doc.data().status !== ORDER_STATUS.placed) {
        throw HttpError.conflict('Only orders that have not been accepted yet can be cancelled.');
      }
      return ORDER_STATUS.cancelled;
    });
    simulator.stop(orderId);
    return order;
  }

  /** Advances an order one step. Returns null if it is missing or finished. */
  async function advanceStatus(orderId) {
    return transition(orderId, (doc) => (doc.exists ? nextStatus(doc.data().status) : null));
  }

  /** Demo endpoint: lets the owner skip the simulator's wait. */
  async function advanceForUser(user, orderId) {
    const order = await transition(orderId, (doc) => {
      assertOwner(user, doc);
      const status = nextStatus(doc.data().status);
      if (!status) throw HttpError.conflict(`Order is already ${doc.data().status}.`);
      return status;
    });

    // Restart the timer so the next automatic step is a full interval away.
    if (nextStatus(order.status)) {
      simulator.start(orderId);
    } else {
      simulator.stop(orderId);
    }
    return order;
  }

  return { create, listForUser, getForUser, cancel, advanceStatus, advanceForUser };
}
