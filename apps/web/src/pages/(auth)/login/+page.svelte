<script lang="ts">
  import { authApi } from '$shared/api/auth.api'
  import { userStore } from '$entities/user'
  import { goto } from '$app/navigation'
  import { i18n } from '$shared/lib/i18n'
  import PasswordInput from '$shared/ui/PasswordInput.svelte'

  let email    = $state('')
  let password = $state('')
  let error    = $state('')
  let loading  = $state(false)

  const handleSubmit = async (e: SubmitEvent) => {
    e.preventDefault()
    error = ''
    loading = true
    try {
      const result = await authApi.login({ email, password })
      localStorage.setItem('access_token', result.accessToken)
      localStorage.setItem('refresh_token', result.refreshToken)
      userStore.set(result.user)
      const returnTo = localStorage.getItem('returnTo')
      localStorage.removeItem('returnTo')
      // Only allow same-origin in-app paths (reject protocol-relative // and /\ to avoid open redirect).
      const safe =
        !!returnTo &&
        returnTo.startsWith('/') &&
        !returnTo.startsWith('//') &&
        !returnTo.startsWith('/\\') &&
        !returnTo.startsWith('/login') &&
        !returnTo.startsWith('/register')
      goto(safe ? returnTo! : '/today')
    } catch {
      // Ignore err.message: the API client's generic 401 handler reports a
      // fixed 'Unauthorized', and the backend's own message ('Invalid
      // credentials') is an untranslated technical string either way —
      // always show the localized, user-facing text instead.
      error = i18n.t('auth.error_invalid')
    } finally {
      loading = false
    }
  }
</script>

<svelte:head><title>{i18n.t('auth.login')} — Locus</title></svelte:head>

<div class="auth-wrap">
  <!-- Left panel -->
  <div class="auth-left">
    <div class="brand" style="position:relative; z-index:1;">
      <div class="brand-logo">L</div>
      <span class="brand-mark">Locus</span>
    </div>

    <div class="auth-pull-quote" style="position:relative; z-index:1;">
      Дисциплина — это не наказание.<br/>
      Это тихая привилегия<br/>
      <span class="accent">выбирать то, что ты оставишь.</span>
    </div>

    <div class="font-mono uppercase" style="font-size:11px; letter-spacing:0.12em; opacity:0.5; position:relative; z-index:1;">
      © 2026 — инструмент самодисциплины
    </div>
  </div>

  <!-- Right panel -->
  <div class="auth-right">
    <div class="auth-form">
      <h1 class="auth-title"><em>С возвращением.</em></h1>
      <p class="auth-sub">Войдите, чтобы продолжить.</p>

      <form onsubmit={handleSubmit}>
        <div class="auth-field">
          <label class="label" for="email">Email</label>
          <!-- svelte-ignore a11y_autofocus -->
          <input
            id="email"
            type="email"
            bind:value={email}
            required
            autofocus
            autocomplete="email"
            placeholder="you@example.com"
            class="input"
          />
        </div>

        <div class="auth-field">
          <label class="label" for="password">Пароль</label>
          <PasswordInput
            id="password"
            bind:value={password}
            required
            autocomplete="current-password"
            placeholder="••••••••"
          />
        </div>

        {#if error}
          <p class="text-[13px] text-danger mb-[10px]">{error}</p>
        {/if}

        <button
          type="submit"
          disabled={loading}
          class="btn primary w-full mt-2"
        >
          {loading ? 'Входим…' : 'Войти'}
        </button>
      </form>

      <p class="auth-foot">
        Нет аккаунта? <a href="/register">Зарегистрироваться</a>
      </p>
    </div>
  </div>
</div>
