import { hash } from 'argon2'
import type { IUserRepository } from '../../domain/user/user.port.js'
import type { User } from '../../domain/user/user.types.js'

export type RegisterInput = {
  email: string
  name: string
  password: string
  timezone?: string
}

export type RegisterResult = { user: User; accessToken: string }

export const registerUseCase = async (
  users: IUserRepository,
  input: RegisterInput,
  signToken: (payload: object) => string,
): Promise<RegisterResult> => {
  const existing = await users.findByEmail(input.email)
  if (existing) throw Object.assign(new Error('Email already in use'), { statusCode: 409 })

  const passwordHash = await hash(input.password)
  const user = await users.create({
    email: input.email,
    name: input.name,
    passwordHash,
    timezone: input.timezone,
  })

  const accessToken = signToken({ id: user.id, email: user.email })
  return { user, accessToken }
}
