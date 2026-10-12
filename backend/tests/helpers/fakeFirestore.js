/**
 * In-memory stand-in for the subset of the firebase-admin Firestore API the
 * services use. Documents live in a Map keyed by full path, so subcollections
 * work the same way as in Firestore.
 */

let autoId = 0;
const nextId = () => `auto${String(++autoId).padStart(6, '0')}`;

const clone = (value) => structuredClone(value);

function getField(data, field) {
  return field.split('.').reduce((value, key) => value?.[key], data);
}

function compare(a, b) {
  const left = a instanceof Date ? a.getTime() : a;
  const right = b instanceof Date ? b.getTime() : b;
  if (left < right) return -1;
  if (left > right) return 1;
  return 0;
}

const operators = {
  '==': (value, target) => compare(value, target) === 0,
  '>=': (value, target) => value !== undefined && compare(value, target) >= 0,
  '<=': (value, target) => value !== undefined && compare(value, target) <= 0,
  'array-contains': (value, target) => Array.isArray(value) && value.includes(target),
};

class DocumentSnapshot {
  constructor(ref, data) {
    this.ref = ref;
    this.id = ref.id;
    this.exists = data !== undefined;
    this._data = data;
  }

  data() {
    return this._data === undefined ? undefined : clone(this._data);
  }

  get(field) {
    return getField(this._data, field);
  }
}

class DocumentReference {
  constructor(store, path) {
    this._store = store;
    this.path = path;
    this.id = path.split('/').at(-1);
  }

  collection(name) {
    return new Query(this._store, `${this.path}/${name}`);
  }

  async get() {
    return new DocumentSnapshot(this, clone(this._store.get(this.path)));
  }

  async set(data, { merge = false } = {}) {
    const existing = merge ? (this._store.get(this.path) ?? {}) : {};
    this._store.set(this.path, clone({ ...existing, ...data }));
  }

  async update(data) {
    if (!this._store.has(this.path)) {
      throw Object.assign(new Error(`No document to update: ${this.path}`), { code: 5 });
    }
    this._store.set(this.path, clone({ ...this._store.get(this.path), ...data }));
  }

  async delete() {
    this._store.delete(this.path);
  }
}

class Query {
  constructor(store, collectionPath, { filters = [], orders = [], limit, after } = {}) {
    this._store = store;
    this._collectionPath = collectionPath;
    this._filters = filters;
    this._orders = orders;
    this._limit = limit;
    this._after = after;
  }

  _with(changes) {
    return new Query(this._store, this._collectionPath, {
      filters: this._filters,
      orders: this._orders,
      limit: this._limit,
      after: this._after,
      ...changes,
    });
  }

  doc(id = nextId()) {
    return new DocumentReference(this._store, `${this._collectionPath}/${id}`);
  }

  async add(data) {
    const ref = this.doc();
    await ref.set(data);
    return ref;
  }

  where(field, op, value) {
    if (!operators[op]) throw new Error(`Fake Firestore does not support "${op}"`);
    return this._with({ filters: [...this._filters, { field, op, value }] });
  }

  orderBy(field, direction = 'asc') {
    return this._with({ orders: [...this._orders, { field, direction }] });
  }

  limit(count) {
    return this._with({ limit: count });
  }

  startAfter(snapshot) {
    return this._with({ after: snapshot });
  }

  _compareDocs(a, b) {
    for (const { field, direction } of this._orders) {
      const result = compare(getField(a.data, field), getField(b.data, field));
      if (result !== 0) return direction === 'desc' ? -result : result;
    }
    // Firestore breaks ties by document id, in the direction of the last orderBy.
    const byId = compare(a.id, b.id);
    return this._orders.at(-1)?.direction === 'desc' ? -byId : byId;
  }

  async get() {
    const prefix = `${this._collectionPath}/`;
    let docs = [...this._store.entries()]
      .filter(([path]) => path.startsWith(prefix) && !path.slice(prefix.length).includes('/'))
      .map(([path, data]) => ({ id: path.slice(prefix.length), path, data }))
      .filter(({ data }) =>
        this._filters.every(({ field, op, value }) => operators[op](getField(data, field), value)),
      )
      .sort((a, b) => this._compareDocs(a, b));

    if (this._after) {
      const cursor = { id: this._after.id, data: this._after.data() };
      docs = docs.filter((doc) => this._compareDocs(doc, cursor) > 0);
    }
    if (this._limit !== undefined) docs = docs.slice(0, this._limit);

    const snapshots = docs.map(
      ({ path, data }) => new DocumentSnapshot(new DocumentReference(this._store, path), clone(data)),
    );
    return { docs: snapshots, size: snapshots.length, empty: snapshots.length === 0 };
  }
}

class Transaction {
  constructor() {
    this._writes = [];
  }

  get(ref) {
    return ref.get();
  }

  set(ref, data, options) {
    this._writes.push(() => ref.set(data, options));
    return this;
  }

  update(ref, data) {
    this._writes.push(() => ref.update(data));
    return this;
  }

  async _commit() {
    for (const write of this._writes) await write();
  }
}

export function createFakeFirestore() {
  const store = new Map();

  return {
    _store: store,

    collection(name) {
      return new Query(store, name);
    },

    doc(path) {
      return new DocumentReference(store, path);
    },

    async getAll(...refs) {
      return Promise.all(refs.map((ref) => ref.get()));
    },

    async runTransaction(fn) {
      const transaction = new Transaction();
      const result = await fn(transaction);
      await transaction._commit();
      return result;
    },
  };
}
