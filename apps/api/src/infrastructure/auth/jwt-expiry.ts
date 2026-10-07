// Access-token lifetime for @fastify/jwt from JWT_EXPIRES_IN.
// A bare number means seconds, as `.env.example` documents (`JWT_EXPIRES_IN=900`).
// @fastify/jwt treats a *number* as seconds but parses a unit-less *string* as
// milliseconds ("900" → 0.9 s), which made every access token expire about a
// second after login — so numeric env values are converted before signing.
export const jwtExpiresIn = (raw: string | undefined = process.env.JWT_EXPIRES_IN): string | number => {
  const value = raw?.trim()
  if (!value) return '15m'
  return /^\d+$/.test(value) ? Number(value) : value
}
