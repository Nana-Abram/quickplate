/**
 * An error that maps directly onto the API error shape:
 * `{ "error": { "code": string, "message": string } }`.
 */
export class HttpError extends Error {
  constructor(status, code, message) {
    super(message);
    this.name = 'HttpError';
    this.status = status;
    this.code = code;
  }

  static validation(message) {
    return new HttpError(400, 'validation_error', message);
  }

  static unauthorized(message = 'Authentication required.') {
    return new HttpError(401, 'unauthorized', message);
  }

  static forbidden(message = 'You do not have access to this resource.') {
    return new HttpError(403, 'forbidden', message);
  }

  static notFound(message = 'Resource not found.') {
    return new HttpError(404, 'not_found', message);
  }

  static conflict(message) {
    return new HttpError(409, 'conflict', message);
  }

  static tooManyRequests(message = 'Too many requests. Try again shortly.') {
    return new HttpError(429, 'rate_limited', message);
  }
}
