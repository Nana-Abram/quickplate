import { ZodError } from 'zod';

import { HttpError } from '../utils/errors.js';

export function notFoundHandler(req, _res, next) {
  next(HttpError.notFound(`No route for ${req.method} ${req.path}.`));
}

function formatZodError(error) {
  return error.issues
    .map((issue) => {
      const path = issue.path.join('.');
      return path ? `${path}: ${issue.message}` : issue.message;
    })
    .join('; ');
}

function toHttpError(error) {
  if (error instanceof HttpError) return error;
  if (error instanceof ZodError) return HttpError.validation(formatZodError(error));
  // Thrown by express.json() when the body is not valid JSON.
  if (error?.type === 'entity.parse.failed') {
    return HttpError.validation('Request body must be valid JSON.');
  }
  return null;
}

/**
 * Turns every error into the API error shape. Unknown errors are logged and
 * reported as `internal` so stack traces and Firebase details never leak.
 */
export function errorHandler(logger) {
  // Express recognises error middleware by its four-argument signature.
  return (error, req, res, _next) => {
    const httpError = toHttpError(error);
    if (httpError) {
      res.status(httpError.status).json({
        error: { code: httpError.code, message: httpError.message },
      });
      return;
    }

    logger.error(`Unhandled error on ${req.method} ${req.originalUrl}`, error);
    res.status(500).json({
      error: { code: 'internal', message: 'Something went wrong. Please try again.' },
    });
  };
}
