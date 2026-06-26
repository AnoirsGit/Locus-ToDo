import { toastStore } from '$shared/lib/toast.svelte'

const BASE_URL = '/api'

type RequestOptions = {
  method?: string
  body?: unknown
  headers?: Record<string, string>
}

class ApiError extends Error {
  constructor(
    public status: number,
    message: string,
  ) {
    super(message)
    this.name = 'ApiError'
  }
}

const getToken = (): string | null =>
  typeof localStorage !== 'undefined' ? localStorage.getItem('access_token') : null

const getRefreshToken = (): string | null =>
  typeof localStorage !== 'undefined' ? localStorage.getItem('refresh_token') : null

const clearSession = () => {
  localStorage.removeItem('access_token')
  localStorage.removeItem('refresh_token')
  localStorage.removeItem('section_prefs')
  localStorage.removeItem('cached_user')
}

const tryRefresh = async (): Promise<string | null> => {
  const refreshToken = getRefreshToken()
  if (!refreshToken) return null
  try {
    const res = await fetch(`${BASE_URL}/auth/refresh`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ refreshToken }),
    })
    if (!res.ok) return null
    const data = await res.json()
    localStorage.setItem('access_token', data.accessToken)
    localStorage.setItem('refresh_token', data.refreshToken)
    return data.accessToken
  } catch {
    return null
  }
}

const doFetch = (path: string, options: RequestOptions, token: string | null) => {
  const { method = 'GET', body, headers = {} } = options
  // No Content-Type on body-less requests: Fastify rejects an empty
  // 'application/json' body with 400 (FST_ERR_CTP_EMPTY_JSON_BODY)
  const reqHeaders: Record<string, string> = { ...headers }
  if (body !== undefined) reqHeaders['Content-Type'] = 'application/json'
  if (token) reqHeaders['Authorization'] = `Bearer ${token}`
  return fetch(`${BASE_URL}${path}`, {
    method,
    headers: reqHeaders,
    body: body ? JSON.stringify(body) : undefined,
  })
}

const request = async <T>(path: string, options: RequestOptions = {}): Promise<T> => {
  let res = await doFetch(path, options, getToken())

  if (res.status === 401 && !path.startsWith('/auth/')) {
    const newToken = await tryRefresh()
    if (newToken) {
      res = await doFetch(path, options, newToken)
    }
  }

  if (res.status === 401) {
    clearSession()
    // Remember where the user was so login can send them back.
    if (typeof window !== 'undefined') {
      const here = window.location.pathname + window.location.search
      if (!here.startsWith('/login') && !here.startsWith('/register')) {
        localStorage.setItem('returnTo', here)
      }
      window.location.href = '/login'
    }
    throw new ApiError(401, 'Unauthorized')
  }

  if (!res.ok) {
    const err = await res.json().catch(() => ({ error: res.statusText }))
    const message = err.error ?? 'Unknown error'
    toastStore.error(message)
    throw new ApiError(res.status, message)
  }

  if (res.status === 204) return undefined as T
  return res.json()
}

export const api = {
  get: <T>(path: string, headers?: Record<string, string>) =>
    request<T>(path, { headers }),
  post: <T>(path: string, body: unknown) =>
    request<T>(path, { method: 'POST', body }),
  patch: <T>(path: string, body: unknown) =>
    request<T>(path, { method: 'PATCH', body }),
  put: <T>(path: string, body: unknown) =>
    request<T>(path, { method: 'PUT', body }),
  delete: <T>(path: string) =>
    request<T>(path, { method: 'DELETE' }),
}

export { ApiError, clearSession }
