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

const request = async <T>(path: string, options: RequestOptions = {}): Promise<T> => {
  const { method = 'GET', body, headers = {} } = options

  const token = getToken()
  const reqHeaders: Record<string, string> = {
    'Content-Type': 'application/json',
    ...headers,
  }
  if (token) reqHeaders['Authorization'] = `Bearer ${token}`

  const res = await fetch(`${BASE_URL}${path}`, {
    method,
    headers: reqHeaders,
    body: body ? JSON.stringify(body) : undefined,
  })

  if (res.status === 401) {
    localStorage.removeItem('access_token')
    window.location.href = '/login'
    throw new ApiError(401, 'Unauthorized')
  }

  if (!res.ok) {
    const err = await res.json().catch(() => ({ error: res.statusText }))
    throw new ApiError(res.status, err.error ?? 'Unknown error')
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
  delete: <T>(path: string) =>
    request<T>(path, { method: 'DELETE' }),
}

export { ApiError }
