import { verify } from 'argon2'
import type { IUserRepository } from '../../domain/user/user.port.js'
import type { User } from '../../domain/user/user.types.js'

export type LoginInput = { email: string; password: string }
export type LoginResult = { user: User; accessToken: string }

export const loginUseCase = async (
  users: IUserRepository,
  input: LoginInput,
  signToken: (payload: object) => string,
): Promise<LoginResult> => {
  const found = await users.findByEmail(input.email)
  const invalid = () => Object.assign(new Error('Invalid credentials'), { statusCode: 401 })

  if (!found) throw invalid()

  const valid = await verify(found.passwordHash, input.password)
  if (!valid) throw invalid()

  const { passwordHash: _, ...user } = found
  const accessToken = signToken({ id: user.id, email: user.email })
  return { user, accessToken }
}
