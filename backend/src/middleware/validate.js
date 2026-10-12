/**
 * Validates request parts against zod schemas and stores the parsed values on
 * `req.valid`. Express 5 makes `req.query` read-only, so parsed data cannot be
 * written back onto the request itself.
 */
export function validate({ body, query, params } = {}) {
  return (req, _res, next) => {
    req.valid = {
      body: body ? body.parse(req.body ?? {}) : undefined,
      query: query ? query.parse(req.query) : undefined,
      params: params ? params.parse(req.params) : undefined,
    };
    next();
  };
}
