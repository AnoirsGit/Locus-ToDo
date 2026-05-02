export type User = {
  id: string
  email: string
  name: string
  avatarUrl?: string
  timezone: string // IANA tz, e.g. 'Europe/Moscow'
  createdAt: string
}

export type AuthTokens = {
  accessToken: string
  refreshToken: string
}

export type AuthResponse = {
  user: User
  token: string
}
