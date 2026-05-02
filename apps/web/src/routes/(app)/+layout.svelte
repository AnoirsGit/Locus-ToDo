<script lang="ts">
  import { Sidebar } from '$widgets/sidebar'
  import type { TaskView } from '$entities/task'
  import type { Snippet } from 'svelte'
  import { page } from '$app/stores'

  type Props = { children: Snippet }
  const { children }: Props = $props()

  const routeToView: Record<string, TaskView> = {
    '/week': 'week',
    '/month': 'month',
    '/year': 'year',
    '/backlog': 'backlog',
    '/archive': 'archive',
  }

  const currentView = $derived(routeToView[$page.url.pathname] ?? 'week')
</script>

<div class="app-shell">
  <Sidebar {currentView} />
  <main>
    {@render children()}
  </main>
</div>

<style>
  .app-shell {
    display: flex;
    min-height: 100vh;
  }

  main {
    flex: 1;
    overflow-y: auto;
  }
</style>
