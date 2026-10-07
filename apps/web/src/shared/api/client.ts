import { toastStore } from '$shared/lib/toast.svelte'
import { i18n } from '$shared/lib/i18n'

const BASE_URL = '/api'

/** Per-call behaviour flags. */
export type CallOptions = {
  /**
   * Background refetch (not user-initiated): an expired session shows a sticky
   * "sign in again" toast instead of navigating away, and failures are left to
   * the caller to report once instead of toasting every request.
   */
  background?: boolean
  /** The caller reports errors itself — skip the generic error toast. */
  quiet?: boolean
}

type RequestOptions = CallOptions & {
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

// ── Token refresh ─────────────────────────────────────────────────────────────

// `expired: true` = the server rejected the refresh token (the session is over).
// `expired: false` = transient failure (offline / 5xx): keep the session.
type RefreshResult = { ok: true; token: string } | { ok: false; expired: boolean }

const tryRefresh = async (): Promise<RefreshResult> => {
  const refreshToken = getRefreshToken()
  if (!refreshToken) return { ok: false, expired: true }
  let res: Response
  try {
    res = await fetch(`${BASE_URL}/auth/refresh`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ refreshToken }),
    })
  } catch {
    return { ok: false, expired: false }
  }
  if (!res.ok) {
    // Another tab may have rotated the pair meanwhile — adopt its tokens.
    const rotated = getRefreshToken()
    const token = getToken()
    if (rotated && rotated !== refreshToken && token) return { ok: true, token }
    return { ok: false, expired: res.status === 400 || res.status === 401 || res.status === 403 }
  }
  try {
    const data = await res.json()
    localStorage.setItem('access_token', data.accessToken)
    localStorage.setItem('refresh_token', data.refreshToken)
    return { ok: true, token: data.accessToken }
  } catch {
    return { ok: false, expired: false }
  }
}

// Refresh tokens rotate on use, so concurrent 401s (e.g. the 15-request
// visibility refetch) must share ONE refresh call: parallel refreshes with the
// same token make all but one fail, which used to log the user out.
let refreshInFlight: Promise<RefreshResult> | null = null

const refreshSession = (): Promise<RefreshResult> => {
  refreshInFlight ??= tryRefresh().finally(() => { refreshInFlight = null })
  return refreshInFlight
}

// ── Session end ───────────────────────────────────────────────────────────────

/** Same-origin in-app path that is safe to return to after login (no open redirect). */
const isReturnablePath = (path: string) =>
  path.startsWith('/') &&
  !path.startsWith('//') &&
  !path.startsWith('/\\') &&
  !path.startsWith('/login') &&
  !path.startsWith('/register')

const goToLogin = () => {
  if (typeof window === 'undefined') return
  // Remember where the user was so login can send them back.
  const here = window.location.pathname + window.location.search
  if (isReturnablePath(here)) localStorage.setItem('returnTo', here)
  // Full reload on purpose: drops every in-memory store of the old session.
  window.location.href = '/login'
}

let expiredToastId: number | null = null

const endSession = (background: boolean) => {
  clearSession()
  if (!background) {
    goToLogin()
    return
  }
  // A background refetch must not yank the user away (they may be mid-edit):
  // keep the page, explain, and let them choose when to sign in again.
  if (expiredToastId !== null && toastStore.has(expiredToastId)) return
  expiredToastId = toastStore.withAction(
    i18n.t('session.expired'),
    { label: i18n.t('session.sign_in'), run: goToLogin },
    'error',
    0,
  )
}

// ── Requests ──────────────────────────────────────────────────────────────────

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

// A 401 from the credential-submission endpoints themselves (wrong password,
// etc.) is not an expired session — there was never a session to expire.
const isCredentialAttempt = (path: string) => path === '/auth/login' || path === '/auth/register'

// Every authenticated call (including /auth/me and /auth/profile) may refresh;
// only the endpoints that issue or revoke tokens themselves must not.
const canRefresh = (path: string) =>
  !isCredentialAttempt(path) && path !== '/auth/refresh' && path !== '/auth/logout'

const request = async <T>(path: string, options: RequestOptions = {}): Promise<T> => {
  const silent = options.quiet || options.background
  const sentToken = getToken()
  let res = await doFetch(path, options, sentToken)

  if (res.status === 401 && canRefresh(path)) {
    // A concurrent request may already have refreshed the session.
    const current = getToken()
    const refreshed: RefreshResult =
      current && current !== sentToken ? { ok: true, token: current } : await refreshSession()
    if (refreshed.ok) {
      res = await doFetch(path, options, refreshed.token)
    } else if (!refreshed.expired) {
      if (!silent) toastStore.error(i18n.t('session.unreachable'))
      throw new ApiError(503, 'Session refresh failed')
    }
  }

  if (res.status === 401 && !isCredentialAttempt(path)) {
    endSession(!!options.background)
    throw new ApiError(401, 'Unauthorized')
  }

  if (!res.ok) {
    const err = await res.json().catch(() => ({ error: res.statusText }))
    const message = err.error ?? 'Unknown error'
    if (!silent) toastStore.error(message)
    throw new ApiError(res.status, message)
  }

  if (res.status === 204) return undefined as T
  return res.json()
}

export const api = {
  get: <T>(path: string, opts?: CallOptions) =>
    request<T>(path, { ...opts }),
  post: <T>(path: string, body: unknown, opts?: CallOptions) =>
    request<T>(path, { ...opts, method: 'POST', body }),
  patch: <T>(path: string, body: unknown, opts?: CallOptions) =>
    request<T>(path, { ...opts, method: 'PATCH', body }),
  put: <T>(path: string, body: unknown, opts?: CallOptions) =>
    request<T>(path, { ...opts, method: 'PUT', body }),
  delete: <T>(path: string, opts?: CallOptions) =>
    request<T>(path, { ...opts, method: 'DELETE' }),
}

export { ApiError, clearSession }
