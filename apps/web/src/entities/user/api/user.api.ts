import { api } from '$shared/api/client'
import type { User, AuthResponse } from '../model/user.types'

type RegisterDto = { email: string; name: string; password: string }
type LoginDto = { email: string; password: string }

export const userApi = {
  register: (dto: RegisterDto) => api.post<AuthResponse>('/auth/register', dto),
  login: (dto: LoginDto) => api.post<AuthResponse>('/auth/login', dto),
  me: () => api.get<User>('/auth/me'),
}
