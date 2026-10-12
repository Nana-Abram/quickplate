/**
 * Thin wrapper around console so services take a logger dependency and tests
 * can pass a silent one.
 */
export const consoleLogger = {
  info: (...args) => console.log('[info]', ...args),
  warn: (...args) => console.warn('[warn]', ...args),
  error: (...args) => console.error('[error]', ...args),
};

export const silentLogger = {
  info: () => {},
  warn: () => {},
  error: () => {},
};
