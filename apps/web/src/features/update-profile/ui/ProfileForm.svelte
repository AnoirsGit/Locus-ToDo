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

  const inputClass = 'bg-gray-800 border border-gray-700 rounded px-3 py-2 text-sm text-white placeholder:text-gray-600 w-full'
  const labelClass = 'text-xs text-gray-400'
</script>

<form onsubmit={handleSubmit} class="flex flex-col gap-4 max-w-sm">
  <div class="flex flex-col gap-1">
    <label for="profile-name" class={labelClass}>Имя</label>
    <input
      id="profile-name"
      type="text"
      bind:value={name}
      placeholder="Ваше имя"
      class={inputClass}
    />
  </div>

  <div class="flex flex-col gap-1">
    <label for="profile-email" class={labelClass}>Email</label>
    <input
      id="profile-email"
      type="email"
      bind:value={email}
      placeholder="email@example.com"
      class={inputClass}
    />
  </div>

  <div class="flex items-center gap-3">
    <button
      type="submit"
      disabled={!name.trim() || !email.trim()}
      class="bg-gray-700 hover:bg-gray-600 disabled:opacity-40 disabled:cursor-not-allowed text-sm text-white px-4 py-2 rounded"
    >
      Сохранить
    </button>
    {#if saved}
      <span class="text-xs text-green-500">Сохранено</span>
    {/if}
  </div>
</form>
