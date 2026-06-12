<script lang="ts">
  import { Sidebar } from '$widgets/sidebar'
  import Toasts from '$shared/ui/Toasts.svelte'
  import { i18n } from '$shared/lib/i18n'
  import { taskStore } from '$entities/task'
  import { tasksApi } from '$entities/task'
  import { userStore } from '$entities/user'
  import { tagStore, TagFilterBar } from '$entities/tag'
  import { authApi } from '$shared/api/auth.api'
  import { toLocalISO, weekStartISO, monthStartISO, yearStartISO } from '$shared/lib/date'
  import { clock } from '$shared/lib/clock.svelte'
  import type { TaskView } from '$entities/task'
  import type { Snippet } from 'svelte'
  import { page } from '$app/stores'
  import { onMount } from 'svelte'
  import { goto } from '$app/navigation'

  type AppView = TaskView | 'settings' | 'stats' | 'docs'

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
    '/stats':    'stats',
    '/notes':    'docs',
  }

  const currentView = $derived(routeToView[$page.url.pathname] ?? 'day')
  let isSidebarOpen = $state(false)
  let isViewDropdownOpen = $state(false)

  // View tab: day/week/month with localStorage persistence
  const VIEW_TAB_KEY = 'view_tab_last_view'
  const viewRoutes: Record<string, string> = { day: '/today', week: '/week', month: '/month' }
  const isViewTab = $derived(['day', 'week', 'month'].includes(currentView))
  const isHorizonView = $derived(['day', 'week', 'month', 'year'].includes(currentView))

  let lastViewRoute = $state('/today')

  $effect(() => {
    if (isViewTab) {
      lastViewRoute = $page.url.pathname
      localStorage.setItem(VIEW_TAB_KEY, $page.url.pathname)
    }
  })

  const REFETCH_THROTTLE_MS = 60_000
  let lastLoadAt = 0

  const loadAll = async () => {
    lastLoadAt = Date.now()
    clock.refresh()
    const now = new Date()
    const weekStart  = weekStartISO(now)
    const monthStart = monthStartISO(now)
    const yearStart  = yearStartISO(now)

    // Load day tasks for today + next 9 days (10 days total)
    const dayDates = Array.from({ length: 10 }, (_, i) => {
      const d = new Date(now)
      d.setDate(d.getDate() + i)
      return toLocalISO(d)
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
  }

  const bootstrap = async () => {
    taskStore.setLoading(true)

    // Initialize locale
    const savedLocale = localStorage.getItem('lang')
    if (savedLocale === 'ru' || savedLocale === 'en') {
      i18n.locale = savedLocale
    }

    // Restore last view tab
    const savedView = localStorage.getItem(VIEW_TAB_KEY)
    if (savedView && ['/today', '/week', '/month'].includes(savedView)) {
      lastViewRoute = savedView
    }

    try {
      if (!localStorage.getItem('access_token')) {
        goto('/login')
        return
      }

      const user = await authApi.me()
      userStore.set(user)

      await loadAll()
      tagStore.load()
      tagStore.loadTaskAssignments()
    } catch (err) {
      console.error('[layout] bootstrap error', err)
      goto('/login')
    } finally {
      taskStore.setLoading(false)
    }
  }

  // Stale-data guard: scheduler transitions run hourly server-side and "today"
  // rolls over at midnight — refetch when the tab becomes visible again.
  const onVisibilityChange = () => {
    if (document.visibilityState !== 'visible') return
    if (Date.now() - lastLoadAt < REFETCH_THROTTLE_MS) return
    if (!localStorage.getItem('access_token')) return
    loadAll().catch((err) => console.error('[layout] background refetch error', err))
  }

  onMount(() => {
    void bootstrap()
    document.addEventListener('visibilitychange', onVisibilityChange)
    return () => document.removeEventListener('visibilitychange', onVisibilityChange)
  })
</script>

<div class="app">
  <header class="mobile-header">
    <div class="flex items-center gap-2">
      <span class="font-display italic text-xl font-medium text-strong">Locus</span>
      <div class="w-1 h-1 rounded-full bg-year mt-1"></div>
    </div>
    <div class="mobile-header-right">
      {#if isViewTab}
        {@const viewLabels: Record<string, string> = {
          day:   i18n.locale === 'ru' ? 'День'   : 'Day',
          week:  i18n.locale === 'ru' ? 'Неделя' : 'Week',
          month: i18n.locale === 'ru' ? 'Месяц'  : 'Month',
        }}
        <div class="view-dropdown-wrap">
          <button
            class="view-dropdown-trigger"
            onclick={() => isViewDropdownOpen = !isViewDropdownOpen}
          >
            {viewLabels[currentView]}
            <svg width="12" height="12" viewBox="0 0 12 12" fill="none" style="transition: transform 150ms" style:transform={isViewDropdownOpen ? 'rotate(180deg)' : 'rotate(0deg)'}>
              <path d="M2 4l4 4 4-4" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
            </svg>
          </button>
          {#if isViewDropdownOpen}
            <div class="view-dropdown-menu">
              {#each [['day', '/today'], ['week', '/week'], ['month', '/month']] as [v, href]}
                <a
                  {href}
                  class="view-dropdown-item"
                  class:active={currentView === v}
                  onclick={() => isViewDropdownOpen = false}
                >{viewLabels[v]}</a>
              {/each}
            </div>
          {/if}
        </div>
      {/if}
      <button
        class="btn-icon"
        onclick={() => isSidebarOpen = true}
        aria-label="Открыть меню"
      >
        <svg width="20" height="20" viewBox="0 0 24 24" fill="none">
          <path d="M4 6h16M4 12h16M4 18h16" stroke="currentColor" stroke-width="2" stroke-linecap="round"/>
        </svg>
      </button>
    </div>
  </header>

  <Sidebar {currentView} isOpen={isSidebarOpen} onClose={() => isSidebarOpen = false} />

  <main class="main overflow-y-auto">
    {#if isHorizonView}
      <nav class="desktop-horizon-tabs">
        <a href="/today" class="horizon-tab" class:active={currentView === 'day'}>
          {i18n.locale === 'ru' ? 'Сегодня' : 'Today'}
        </a>
        <a href="/week" class="horizon-tab" class:active={currentView === 'week'}>
          {i18n.locale === 'ru' ? 'Неделя' : 'Week'}
        </a>
        <a href="/month" class="horizon-tab" class:active={currentView === 'month'}>
          {i18n.locale === 'ru' ? 'Месяц' : 'Month'}
        </a>
        <a href="/year" class="horizon-tab" class:active={currentView === 'year'}>
          {i18n.locale === 'ru' ? 'Год' : 'Year'}
        </a>
      </nav>
    {/if}
    {#if isHorizonView || currentView === 'backlog'}
      <div class="tag-filter-wrap">
        <TagFilterBar
          activeIds={tagStore.filterTagIds}
          isFiltering={tagStore.isFiltering}
          onToggle={(id) => tagStore.toggleFilterTag(id)}
          onClear={() => tagStore.clearFilter()}
        />
      </div>
    {/if}
    {@render children()}
  </main>

  <Toasts />

  <nav class="bottom-nav">
    <a href={lastViewRoute} class="bottom-nav-item" class:active={isViewTab}>
      <svg class="bottom-nav-icon" viewBox="0 0 24 24" fill="none">
        <rect x="3" y="3" width="7" height="7" rx="1" stroke="currentColor" stroke-width="2"/>
        <rect x="14" y="3" width="7" height="7" rx="1" stroke="currentColor" stroke-width="2"/>
        <rect x="3" y="14" width="7" height="7" rx="1" stroke="currentColor" stroke-width="2"/>
        <rect x="14" y="14" width="7" height="7" rx="1" stroke="currentColor" stroke-width="2"/>
      </svg>
      {i18n.locale === 'ru' ? 'Просмотр' : 'View'}
    </a>
    <a href="/backlog" class="bottom-nav-item" class:active={currentView === 'backlog'}>
      <svg class="bottom-nav-icon" viewBox="0 0 24 24" fill="none">
        <path d="M4 6h16M4 12h10M4 18h7" stroke="currentColor" stroke-width="2" stroke-linecap="round"/>
      </svg>
      {i18n.locale === 'ru' ? 'Бэклог' : 'Backlog'}
    </a>
    <a href="/notes" class="bottom-nav-item" class:active={currentView === 'docs'}>
      <svg class="bottom-nav-icon" viewBox="0 0 24 24" fill="none">
        <rect x="4" y="2" width="16" height="20" rx="2" stroke="currentColor" stroke-width="2"/>
        <path d="M8 8h8M8 12h8M8 16h5" stroke="currentColor" stroke-width="2" stroke-linecap="round"/>
      </svg>
      {i18n.locale === 'ru' ? 'Заметки' : 'Notes'}
    </a>
    <a href="/settings" class="bottom-nav-item" class:active={currentView === 'settings'}>
      <svg class="bottom-nav-icon" viewBox="0 0 24 24" fill="none">
        <circle cx="12" cy="12" r="3" stroke="currentColor" stroke-width="2"/>
        <path d="M12 2v2M12 20v2M4.22 4.22l1.42 1.42M18.36 18.36l1.42 1.42M2 12h2M20 12h2M4.22 19.78l1.42-1.42M18.36 5.64l1.42-1.42" stroke="currentColor" stroke-width="2" stroke-linecap="round"/>
      </svg>
      {i18n.locale === 'ru' ? 'Профиль' : 'Profile'}
    </a>
  </nav>
</div>
