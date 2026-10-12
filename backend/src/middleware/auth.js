import { HttpError } from '../utils/errors.js';

/**
 * Verifies the Firebase ID token in `Authorization: Bearer <token>` and puts
 * the caller on `req.user`.
 */
export function requireAuth(auth) {
  return async (req, _res, next) => {
    const [scheme, token] = (req.get('authorization') ?? '').split(' ');
    if (scheme !== 'Bearer' || !token) {
      throw HttpError.unauthorized('Missing bearer token.');
    }

    let decoded;
    try {
      decoded = await auth.verifyIdToken(token);
    } catch {
      throw HttpError.unauthorized('Invalid or expired token.');
    }

    req.user = { uid: decoded.uid, name: decoded.name ?? null };
    next();
  };
}
