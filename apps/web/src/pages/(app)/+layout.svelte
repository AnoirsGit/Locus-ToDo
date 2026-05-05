<script lang="ts">
  import { Sidebar } from '$widgets/sidebar'
  import { taskStore } from '$entities/task'
  import { tasksApi } from '$entities/task'
  import { userStore } from '$entities/user'
  import { authApi } from '$shared/api/auth.api'
  import type { TaskView } from '$entities/task'
  import type { Snippet } from 'svelte'
  import { page } from '$app/stores'
  import { onMount } from 'svelte'
  import { goto } from '$app/navigation'

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

  const toISO = (d: Date) => d.toISOString().split('T')[0]

  const getMondayOfWeek = (d: Date) => {
    const r = new Date(d)
    const day = r.getDay()
    r.setDate(r.getDate() - (day === 0 ? 6 : day - 1))
    return toISO(r)
  }

  const getMonthStart = (d: Date) =>
    `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-01`

  const getYearStart = (d: Date) => `${d.getFullYear()}-01-01`

  onMount(async () => {
    taskStore.setLoading(true)

    try {
      if (!localStorage.getItem('access_token')) {
        goto('/login')
        return
      }

      const user = await authApi.me()
      userStore.set(user)

      const now = new Date()
      const today      = toISO(now)
      const weekStart  = getMondayOfWeek(now)
      const monthStart = getMonthStart(now)
      const yearStart  = getYearStart(now)

      const [day, week, month, year] = await Promise.all([
        tasksApi.getByPeriod({ periodType: 'day',   periodStart: today }),
        tasksApi.getByPeriod({ periodType: 'week',  periodStart: weekStart }),
        tasksApi.getByPeriod({ periodType: 'month', periodStart: monthStart }),
        tasksApi.getByPeriod({ periodType: 'year',  periodStart: yearStart }),
      ])

      taskStore.setItems([...day, ...week, ...month, ...year])
    } catch (err) {
      console.error('[layout] bootstrap error', err)
      goto('/login')
    } finally {
      taskStore.setLoading(false)
    }
  })
</script>

<div class="app">
  <Sidebar {currentView} />
  <main class="main overflow-y-auto">
    {@render children()}
  </main>
</div>
