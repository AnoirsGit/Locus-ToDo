import { api } from './client'

type LoginDto  = { email: string; password: string }
type AuthResult = { accessToken: string; user: { id: string; name: string; email: string; timezone: string; createdAt: string } }

export const authApi = {
  login:    (dto: LoginDto)  => api.post<AuthResult>('/auth/login', dto),
  register: (dto: LoginDto & { name: string; timezone?: string }) => api.post<AuthResult>('/auth/register', dto),
  me:       () => api.get<AuthResult['user']>('/auth/me'),
}
