<script lang="ts">
  import { Sidebar } from '$widgets/sidebar'
  import { i18n } from '$shared/lib/i18n'
  import { taskStore } from '$entities/task'
  import { tasksApi } from '$entities/task'
  import { userStore } from '$entities/user'
  import { authApi } from '$shared/api/auth.api'
  import type { TaskView } from '$entities/task'
  import type { Snippet } from 'svelte'
  import { page } from '$app/stores'
  import { onMount } from 'svelte'
  import { goto } from '$app/navigation'
  import { devTime } from '$shared/lib/devTime.svelte'
  import DevTimePicker from '$shared/ui/DevTimePicker.svelte'

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
  let isSidebarOpen = $state(false)

  const toISO = (d: Date) => d.toISOString().split('T')[0]

  const getMondayOfWeek = (d: Date) => {
    const r = new Date(d)
    const day = r.getUTCDay()
    r.setUTCDate(r.getUTCDate() - (day === 0 ? 6 : day - 1))
    return toISO(r)
  }

  const getMonthStart = (d: Date) =>
    `${d.getUTCFullYear()}-${String(d.getUTCMonth() + 1).padStart(2, '0')}-01`

  const getYearStart = (d: Date) => `${d.getUTCFullYear()}-01-01`

  onMount(async () => {
    taskStore.setLoading(true)
    
    // Initialize locale
    const savedLocale = localStorage.getItem('lang')
    if (savedLocale === 'ru' || savedLocale === 'en') {
      i18n.locale = savedLocale
    }

    try {
      if (!localStorage.getItem('access_token')) {
        goto('/login')
        return
      }

      const user = await authApi.me()
      userStore.set(user)

      const now = devTime.now()
      const weekStart  = getMondayOfWeek(now)
      const monthStart = getMonthStart(now)
      const yearStart  = getYearStart(now)

      // Load day tasks for today + next 9 days (10 days total)
      const dayDates = Array.from({ length: 10 }, (_, i) => {
        const d = new Date(now)
        d.setUTCDate(d.getUTCDate() + i)
        return toISO(d)
      })

      const [dayResults, week, month, year, backlog, archive] = await Promise.all([
        Promise.all(dayDates.map(date => tasksApi.getByPeriod({ periodType: 'day', periodStart: date }))),
        tasksApi.getByPeriod({ periodType: 'week',  periodStart: weekStart }),
        tasksApi.getByPeriod({ periodType: 'month', periodStart: monthStart }),
        tasksApi.getByPeriod({ periodType: 'year',  periodStart: yearStart }),
        tasksApi.getBacklog(),
        tasksApi.getArchive(),
      ])

      taskStore.setItems([...dayResults.flat(), ...week, ...month, ...year, ...backlog, ...archive])
    } catch (err) {
      console.error('[layout] bootstrap error', err)
      goto('/login')
    } finally {
      taskStore.setLoading(false)
    }
  })
</script>

<div class="app">
  <header class="mobile-header">
    <div class="flex items-center gap-2">
      <span class="font-display italic text-xl font-medium text-strong">Locus</span>
      <div class="w-1 h-1 rounded-full bg-year mt-1"></div>
    </div>
    <button 
      class="btn-icon" 
      onclick={() => isSidebarOpen = true}
      aria-label="Открыть меню"
    >
      <svg width="20" height="20" viewBox="0 0 24 24" fill="none">
        <path d="M4 6h16M4 12h16M4 18h16" stroke="currentColor" stroke-width="2" stroke-linecap="round"/>
      </svg>
    </button>
  </header>

  <Sidebar {currentView} isOpen={isSidebarOpen} onClose={() => isSidebarOpen = false} />
  
  <main class="main overflow-y-auto">
    {@render children()}
  </main>

  {#if import.meta.env.DEV}
    <div class="dev-time-wrap">
      <DevTimePicker />
    </div>
  {/if}

  <nav class="bottom-nav">
    <a href="/today" class="bottom-nav-item" class:active={currentView === 'day'}>
      <svg class="bottom-nav-icon" viewBox="0 0 24 24" fill="none">
        <rect x="3" y="4" width="18" height="16" rx="2" stroke="currentColor" stroke-width="2"/>
        <path d="M16 2v4M8 2v4M3 10h18" stroke="currentColor" stroke-width="2" stroke-linecap="round"/>
      </svg>
      Сегодня
    </a>
    <a href="/week" class="bottom-nav-item" class:active={currentView === 'week'}>
      <svg class="bottom-nav-icon" viewBox="0 0 24 24" fill="none">
        <path d="M3 3h18v18H3z" stroke="currentColor" stroke-width="2"/>
        <path d="M9 3v18M15 3v18M3 9h18M3 15h18" stroke="currentColor" stroke-width="2"/>
      </svg>
      Неделя
    </a>
    <a href="/month" class="bottom-nav-item" class:active={currentView === 'month'}>
      <svg class="bottom-nav-icon" viewBox="0 0 24 24" fill="none">
        <path d="M8 2v4M16 2v4M3 10h18" stroke="currentColor" stroke-width="2" stroke-linecap="round"/>
        <rect x="3" y="4" width="18" height="16" rx="2" stroke="currentColor" stroke-width="2"/>
        <path d="M7 14h2M11 14h2M15 14h2M7 18h2M11 18h2M15 18h2" stroke="currentColor" stroke-width="2" stroke-linecap="round"/>
      </svg>
      Месяц
    </a>
  </nav>
</div>
