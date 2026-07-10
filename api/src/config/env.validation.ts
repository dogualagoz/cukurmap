const REQUIRED_VARS = ['DATABASE_URL', 'JWT_SECRET', 'DEVICE_PEPPER'] as const;
const MIN_SECRET_LENGTH = 32;

export function validateEnv(config: Record<string, unknown>) {
  const missing = REQUIRED_VARS.filter((key) => !config[key]);
  if (missing.length > 0) {
    throw new Error(
      `Missing required environment variables: ${missing.join(', ')}`,
    );
  }
  const weak = (['JWT_SECRET', 'DEVICE_PEPPER'] as const).filter(
    (key) => String(config[key]).length < MIN_SECRET_LENGTH,
  );
  if (weak.length > 0) {
    throw new Error(
      `Secrets shorter than ${MIN_SECRET_LENGTH} chars: ${weak.join(', ')} (generate with: openssl rand -hex 32)`,
    );
  }
  return config;
}
