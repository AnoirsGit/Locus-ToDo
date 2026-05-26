import { api, clearSession } from './client'

type LoginDto  = { email: string; password: string }
type AuthResult = {
  accessToken: string
  refreshToken: string
  user: { id: string; name: string; email: string; timezone: string; createdAt: string }
}

export const authApi = {
  login:    (dto: LoginDto) => api.post<AuthResult>('/auth/login', dto),
  register: (dto: LoginDto & { name: string; timezone?: string }) => api.post<AuthResult>('/auth/register', dto),
  me:       () => api.get<AuthResult['user']>('/auth/me'),
  refresh:  (refreshToken: string) => api.post<{ accessToken: string; refreshToken: string }>('/auth/refresh', { refreshToken }),
  updateProfile: (patch: { name?: string; email?: string }) =>
    api.patch<AuthResult['user']>('/auth/profile', patch),
  logout:   async () => {
    const refreshToken = typeof localStorage !== 'undefined' ? localStorage.getItem('refresh_token') : null
    if (refreshToken) {
      await api.post('/auth/logout', { refreshToken }).catch(() => {})
    }
    clearSession()
  },
}
