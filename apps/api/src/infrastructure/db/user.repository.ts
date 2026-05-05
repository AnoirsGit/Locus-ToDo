import type { IUserRepository, CreateUserInput } from '../../domain/user/user.port.js'
import type { User, UserWithHash, UserSettings } from '../../domain/user/user.types.js'
import { db } from './client.js'

export const userRepository: IUserRepository = {
  async findByEmail(email) {
    const [row] = await db<UserWithHash[]>`
      SELECT id, email, name, timezone, avatar_url, password_hash, created_at
      FROM users WHERE email = ${email}
    `
    return row ?? null
  },

  async findById(id) {
    const [row] = await db<User[]>`
      SELECT id, email, name, timezone, avatar_url, created_at
      FROM users WHERE id = ${id}
    `
    return row ?? null
  },

  async create({ email, name, passwordHash, timezone = 'UTC' }) {
    const [user] = await db<User[]>`
      INSERT INTO users (email, name, password_hash, timezone)
      VALUES (${email}, ${name}, ${passwordHash}, ${timezone})
      RETURNING id, email, name, timezone, avatar_url, created_at
    `
    await db`INSERT INTO user_settings (user_id) VALUES (${user.id})`
    return user
  },

  async getSettings(userId) {
    const [row] = await db<UserSettings[]>`
      SELECT user_id, notification_offset_min, notify_overdue,
             notify_daily_summary, daily_summary_time
      FROM user_settings WHERE user_id = ${userId}
    `
    return row
  },

  async updateSettings(userId, patch) {
    const entries = Object.entries(patch).filter(([, v]) => v !== undefined)
    if (entries.length === 0) return this.getSettings(userId)

    const setCols = entries.map(([k], i) => `${toSnake(k)} = $${i + 2}`).join(', ')
    const values = [userId, ...entries.map(([, v]) => v)]

    const [row] = await db.unsafe<UserSettings[]>(
      `UPDATE user_settings SET ${setCols}
       WHERE user_id = $1
       RETURNING user_id, notification_offset_min, notify_overdue, notify_daily_summary, daily_summary_time`,
      values as string[],
    )
    return row
  },
}

const toSnake = (s: string) => s.replace(/[A-Z]/g, (c) => `_${c.toLowerCase()}`)
