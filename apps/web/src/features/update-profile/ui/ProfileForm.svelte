<script lang="ts">
  import { authApi } from '$shared/api/auth.api'
  import { userStore } from '$entities/user'
  import { i18n } from '$shared/lib/i18n'

  const user = $derived(userStore.user)

  let name = $state(user?.name ?? '')
  let email = $state(user?.email ?? '')
  let saved = $state(false)
  let error = $state('')
  let loading = $state(false)

  const handleSubmit = async (e: SubmitEvent) => {
    e.preventDefault()
    if (!name.trim() || !email.trim()) return
    loading = true
    error = ''
    try {
      const updated = await authApi.updateProfile({ name: name.trim(), email: email.trim() })
      userStore.patch({ name: updated.name, email: updated.email })
      saved = true
      setTimeout(() => { saved = false }, 2000)
    } catch (err: any) {
      error = err.message ?? i18n.t('action.save_error')
    } finally {
      loading = false
    }
  }
</script>

<form onsubmit={handleSubmit} class="flex flex-col gap-4 max-w-sm">
  <div class="auth-field">
    <label class="label" for="profile-name">{i18n.t('auth.name')}</label>
    <input
      id="profile-name"
      type="text"
      bind:value={name}
      placeholder={i18n.t('auth.name_placeholder')}
      class="input"
    />
  </div>

  <div class="auth-field">
    <label class="label" for="profile-email">Email</label>
    <input
      id="profile-email"
      type="email"
      bind:value={email}
      placeholder="email@example.com"
      class="input"
    />
  </div>

  <div class="flex items-center gap-3">
    <button
      type="submit"
      disabled={loading || !name.trim() || !email.trim()}
      class="btn primary"
    >
      {loading ? i18n.t('action.saving') : i18n.t('action.save')}
    </button>
    {#if saved}
      <span class="font-mono text-[11px] text-success">{i18n.t('action.saved')}</span>
    {/if}
    {#if error}
      <span class="font-mono text-[11px] text-danger">{error}</span>
    {/if}
  </div>
</form>
