<script lang="ts">
  import { Sidebar } from '$widgets/sidebar'
  import { taskStore, MOCK_TASKS } from '$entities/task'
  import { userStore } from '$entities/user'
  import type { TaskView } from '$entities/task'
  import type { Snippet } from 'svelte'
  import { page } from '$app/stores'
  import { onMount } from 'svelte'

  type AppView = TaskView | 'settings'

  type Props = { children: Snippet }
  const { children }: Props = $props()

  const routeToView: Record<string, AppView> = {
    '/today':    'day',
    '/week':     'week',
    '/month':    'month',
    '/year':     'year',
    '/backlog':  'backlog',
    '/archive':  'archive',
    '/settings': 'settings',
  }

  const currentView = $derived(routeToView[$page.url.pathname] ?? 'day')

  onMount(() => {
    taskStore.setItems(MOCK_TASKS)
    userStore.set({
      id: 'u1',
      name: 'Иван Петров',
      email: 'ivan@example.com',
      timezone: 'Europe/Moscow',
      createdAt: '2026-01-01',
    })
  })
</script>

<div class="flex min-h-screen">
  <Sidebar {currentView} />
  <main class="flex-1 overflow-y-auto">
    {@render children()}
  </main>
</div>
