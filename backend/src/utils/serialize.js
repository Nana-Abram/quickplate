/**
 * Converts a Firestore Timestamp (or a Date) to an ISO string for JSON
 * responses. Returns null for missing values.
 */
export function toIsoString(value) {
  if (!value) return null;
  if (typeof value.toDate === 'function') return value.toDate().toISOString();
  if (value instanceof Date) return value.toISOString();
  return null;
}
