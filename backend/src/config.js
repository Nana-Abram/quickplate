import { z } from 'zod';

const booleanString = z
  .enum(['true', 'false'])
  .default('false')
  .transform((value) => value === 'true');

const envSchema = z.object({
  NODE_ENV: z.enum(['development', 'test', 'production']).default('development'),
  PORT: z.coerce.number().int().positive().default(4000),
  GOOGLE_APPLICATION_CREDENTIALS: z.string().min(1).optional(),
  FIREBASE_SERVICE_ACCOUNT_JSON: z.string().min(1).optional(),
  ENABLE_DEMO_ENDPOINTS: booleanString,
  SIM_STEP_SECONDS: z.coerce.number().int().min(0).default(20),
  CORS_ORIGIN: z.string().min(1).default('*'),
  RATE_LIMIT_PER_MINUTE: z.coerce.number().int().positive().default(120),
  // Proxies in front of the API (Render has one). Needed so the rate limit
  // sees each client's IP instead of the proxy's.
  TRUST_PROXY_HOPS: z.coerce.number().int().min(0).default(0),
  // How long restaurant and menu reads are served from memory.
  RESTAURANT_CACHE_SECONDS: z.coerce.number().int().min(0).default(60),
});

/**
 * Parses and validates environment variables. Fails fast at boot so a
 * misconfigured deploy never starts serving requests.
 */
export function loadConfig(env = process.env) {
  const result = envSchema.safeParse(env);
  if (!result.success) {
    const details = result.error.issues
      .map((issue) => `${issue.path.join('.')}: ${issue.message}`)
      .join('; ');
    throw new Error(`Invalid environment configuration: ${details}`);
  }

  const parsed = result.data;
  return {
    env: parsed.NODE_ENV,
    port: parsed.PORT,
    credentialsPath: parsed.GOOGLE_APPLICATION_CREDENTIALS,
    serviceAccountJson: parsed.FIREBASE_SERVICE_ACCOUNT_JSON,
    enableDemoEndpoints: parsed.ENABLE_DEMO_ENDPOINTS,
    simStepSeconds: parsed.SIM_STEP_SECONDS,
    corsOrigins: parsed.CORS_ORIGIN.split(',').map((origin) => origin.trim()),
    rateLimitPerMinute: parsed.RATE_LIMIT_PER_MINUTE,
    trustProxyHops: parsed.TRUST_PROXY_HOPS,
    restaurantCacheSeconds: parsed.RESTAURANT_CACHE_SECONDS,
  };
}
