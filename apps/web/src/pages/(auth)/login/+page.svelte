<script lang="ts">
  import { authApi } from '$shared/api/auth.api'
  import { userStore } from '$entities/user'
  import { goto } from '$app/navigation'
  import { i18n } from '$shared/lib/i18n'

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
      goto('/today')
    } catch (err: any) {
      error = err.message ?? i18n.t('auth.error_invalid')
    } finally {
      loading = false
    }
  }
</script>

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
          <input
            id="email"
            type="email"
            bind:value={email}
            required
            autocomplete="email"
            placeholder="you@example.com"
            class="input"
          />
        </div>

        <div class="auth-field">
          <label class="label" for="password">Пароль</label>
          <input
            id="password"
            type="password"
            bind:value={password}
            required
            autocomplete="current-password"
            placeholder="••••••••"
            class="input"
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
