<script lang="ts">
  import { authApi } from '$shared/api/auth.api'
  import { ApiError } from '$shared/api/client'
  import { userStore } from '$entities/user'
  import { goto } from '$app/navigation'
  import { i18n } from '$shared/lib/i18n'
  import PasswordInput from '$shared/ui/PasswordInput.svelte'

  let name     = $state('')
  let email    = $state('')
  let password = $state('')
  let error    = $state('')
  let loading  = $state(false)

  const handleSubmit = async (e: SubmitEvent) => {
    e.preventDefault()
    error = ''
    loading = true
    try {
      const result = await authApi.register({ name, email, password })
      localStorage.setItem('access_token', result.accessToken)
      localStorage.setItem('refresh_token', result.refreshToken)
      userStore.set(result.user)
      localStorage.removeItem('returnTo')
      goto('/today')
    } catch (err) {
      // The API's message ('Email already in use', validation dumps) is an
      // untranslated technical string, and an ApiError always carries one, so
      // the localized fallback never showed. Map the status instead.
      error = err instanceof ApiError && err.status === 409
        ? i18n.t('auth.error_exists')
        : i18n.t('auth.error_register')
    } finally {
      loading = false
    }
  }
</script>

<svelte:head><title>{i18n.t('auth.register')} — Locus</title></svelte:head>

<div class="auth-wrap">
  <!-- Left panel -->
  <div class="auth-left">
    <div class="brand" style="position:relative; z-index:1;">
      <div class="brand-logo">L</div>
      <span class="brand-mark">Locus</span>
    </div>

    <div class="auth-pull-quote" style="position:relative; z-index:1;">
      {i18n.t('auth.register_quote_1')}<br/>
      {i18n.t('auth.register_quote_2')}<br/>
      <span class="accent">{i18n.t('auth.register_quote_3')}</span>
    </div>

    <div class="font-mono uppercase" style="font-size:11px; letter-spacing:0.12em; opacity:0.5; position:relative; z-index:1;">
      {i18n.t('auth.register_footer')}
    </div>
  </div>

  <!-- Right panel -->
  <div class="auth-right">
    <div class="auth-form">
      <h1 class="auth-title"><em>{i18n.t('auth.register_title')}</em></h1>
      <p class="auth-sub">{i18n.t('auth.register_sub')}</p>

      <form onsubmit={handleSubmit}>
        <div class="auth-field">
          <label class="label" for="name">{i18n.t('auth.name')}</label>
          <!-- svelte-ignore a11y_autofocus -->
          <input
            id="name"
            type="text"
            bind:value={name}
            required
            autofocus
            autocomplete="name"
            placeholder={i18n.t('auth.name_question')}
            class="input"
          />
        </div>

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
          <label class="label" for="password">{i18n.t('auth.password')}</label>
          <PasswordInput
            id="password"
            bind:value={password}
            required
            minlength={8}
            autocomplete="new-password"
            placeholder={i18n.t('auth.password_min')}
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
          {loading ? i18n.t('auth.register_loading') : i18n.t('auth.register_submit')}
        </button>
      </form>

      <p class="auth-foot">
        {i18n.t('auth.have_account')} <a href="/login">{i18n.t('auth.login_submit')}</a>
      </p>
    </div>
  </div>
</div>
