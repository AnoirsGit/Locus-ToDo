<script lang="ts">
  import { userStore } from '$entities/user'

  const user = $derived(userStore.user)

  let name = $state(user?.name ?? '')
  let email = $state(user?.email ?? '')
  let saved = $state(false)

  const handleSubmit = (e: SubmitEvent) => {
    e.preventDefault()
    if (!name.trim() || !email.trim()) return
    userStore.patch({ name: name.trim(), email: email.trim() })
    saved = true
    setTimeout(() => { saved = false }, 2000)
  }
</script>

<form onsubmit={handleSubmit} class="flex flex-col gap-4 max-w-sm">
  <div class="auth-field">
    <label class="label" for="profile-name">Имя</label>
    <input
      id="profile-name"
      type="text"
      bind:value={name}
      placeholder="Ваше имя"
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
      disabled={!name.trim() || !email.trim()}
      class="btn primary"
    >
      Сохранить
    </button>
    {#if saved}
      <span class="font-mono" style="font-size:11px; color:var(--color-success);">Сохранено</span>
    {/if}
  </div>
</form>
