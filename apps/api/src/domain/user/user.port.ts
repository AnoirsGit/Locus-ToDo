import type { User, UserWithHash, UserSettings } from './user.types.js'

export type CreateUserInput = {
  email: string
  name: string
  passwordHash: string
  timezone?: string
}

export type IUserRepository = {
  findByEmail(email: string): Promise<UserWithHash | null>
  findById(id: string): Promise<User | null>
  create(input: CreateUserInput): Promise<User>
  getSettings(userId: string): Promise<UserSettings>
  updateSettings(userId: string, patch: Partial<Omit<UserSettings, 'userId'>>): Promise<UserSettings>
}
