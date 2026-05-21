import { randomBytes } from 'crypto'
import type { Redis } from 'ioredis'

const PREFIX = 'refresh_token:'
const TTL_SECONDS = 30 * 24 * 60 * 60 // 30 days

const key = (token: string) => `${PREFIX}${token}`

export const createRefreshTokenService = (redis: Redis) => ({
  /**
   * Generate a new refresh token, store userId in Redis with 30-day TTL.
   * Returns the raw token string.
   */
  create: async (userId: string): Promise<string> => {
    const token = randomBytes(48).toString('hex')
    await redis.set(key(token), userId, 'EX', TTL_SECONDS)
    return token
  },

  /**
   * Validate a refresh token.
   * Returns the userId it belongs to, or null if invalid/expired.
   */
  validate: async (token: string): Promise<string | null> => {
    return redis.get(key(token))
  },

  /**
   * Rotate: delete old token, create and store a new one for the same user.
   * Returns the new token string.
   */
  rotate: async (oldToken: string, userId: string): Promise<string> => {
    await redis.del(key(oldToken))
    return createRefreshTokenService(redis).create(userId)
  },

  /**
   * Revoke a refresh token (logout).
   */
  revoke: async (token: string): Promise<void> => {
    await redis.del(key(token))
  },
})

export type RefreshTokenService = ReturnType<typeof createRefreshTokenService>
