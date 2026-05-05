<script lang="ts">
  import { authApi } from '$shared/api/auth.api'
  import { userStore } from '$entities/user'
  import { goto } from '$app/navigation'

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
      userStore.set(result.user)
      goto('/today')
    } catch (err: any) {
      error = err.message ?? 'Не удалось зарегистрироваться'
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
      Начни там, где стоишь.<br/>
      Locus будет держать тебя<br/>
      <span class="accent">верным тому, чего ты хотел.</span>
    </div>

    <div class="font-mono uppercase" style="font-size:11px; letter-spacing:0.12em; opacity:0.5; position:relative; z-index:1;">
      Три правила · честность · системность · рефлексия
    </div>
  </div>

  <!-- Right panel -->
  <div class="auth-right">
    <div class="auth-form">
      <h1 class="auth-title"><em>Новый аккаунт.</em></h1>
      <p class="auth-sub">Бесплатно, пока ты пользуешься.</p>

      <form onsubmit={handleSubmit}>
        <div class="auth-field">
          <label class="label" for="name">Имя</label>
          <input
            id="name"
            type="text"
            bind:value={name}
            required
            autocomplete="name"
            placeholder="Как тебя зовут?"
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
          <label class="label" for="password">Пароль</label>
          <input
            id="password"
            type="password"
            bind:value={password}
            required
            minlength={8}
            autocomplete="new-password"
            placeholder="Минимум 8 символов"
            class="input"
          />
        </div>

        {#if error}
          <p style="font-size:13px; color:var(--color-danger); margin:0 0 10px;">{error}</p>
        {/if}

        <button
          type="submit"
          disabled={loading}
          class="btn primary"
          style="width:100%; margin-top:8px;"
        >
          {loading ? 'Создаём аккаунт…' : 'Создать аккаунт'}
        </button>
      </form>

      <p class="auth-foot">
        Уже есть аккаунт? <a href="/login">Войти</a>
      </p>
    </div>
  </div>
</div>
