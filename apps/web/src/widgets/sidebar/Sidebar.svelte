<script lang="ts">
  import type { TaskView } from '$entities/task'
  import { taskStore } from '$entities/task'
  import { i18n } from '$shared/lib/i18n'
  import { clock } from '$shared/lib/clock.svelte'
  import { userStore } from '$entities/user'
  import { authApi } from '$shared/api/auth.api'
  import { goto } from '$app/navigation'
  import { onMount } from 'svelte'

  type AppView = TaskView | 'settings' | 'stats' | 'docs'
  type Props = {
    currentView: AppView
    isOpen?: boolean
    onClose?: () => void
  }
  const { currentView, isOpen = false, onClose }: Props = $props()

  // Task counts per view
  const today = $derived(clock.today)
  const counts = $derived({
    day:     taskStore.getForDate(today).filter(t => t.period.status !== 'archived' && t.period.status !== 'backlog').length,
    week:    taskStore.items.filter(t => t.level === 'week'  && ['todo','done','overdue'].includes(t.period.status)).length,
    month:   taskStore.items.filter(t => t.level === 'month' && ['todo','done','overdue'].includes(t.period.status)).length,
    year:    taskStore.items.filter(t => t.level === 'year'  && ['todo','done','overdue'].includes(t.period.status)).length,
    backlog: taskStore.items.filter(t => t.period.status === 'backlog').length,
    archive: taskStore.items.filter(t => t.period.status === 'archived').length,
  })

  let theme = $state<'light' | 'dark'>('light')
  onMount(() => {
    theme = (localStorage.getItem('theme') as 'light' | 'dark') || 'light'
  })

  const toggleTheme = () => {
    theme = theme === 'dark' ? 'light' : 'dark'
    document.documentElement.dataset.theme = theme
    localStorage.setItem('theme', theme)
  }

  const toggleLocale = () => {
    i18n.locale = i18n.locale === 'ru' ? 'en' : 'ru'
  }

  const logout = async () => {
    await authApi.logout()
    goto('/login')
  }
</script>

<div
  class="sidebar-backdrop"
  class:show={isOpen}
  onclick={onClose}
  onkeydown={(e) => e.key === 'Escape' && onClose?.()}
  role="button"
  tabindex="-1"
  aria-label="Close menu"
></div>

<aside class="sidebar" class:open={isOpen}>

  <!-- Brand -->
  <div class="brand">
    <span class="brand-mark">Locus</span>
    <span class="brand-dot"></span>
  </div>

  <!-- Horizons -->
  <div class="nav-section">
    <span class="nav-label">{i18n.t('nav.horizons')}</span>

    <a href="/today"  class="nav-item" onclick={onClose} class:active={currentView === 'day'}>
      <svg class="nav-icon" viewBox="0 0 16 16" fill="none">
        <rect x="1.5" y="2.5" width="13" height="11" rx="1.5" stroke="currentColor" stroke-width="1.2"/>
        <path d="M5 1.5v2M11 1.5v2M1.5 6h13" stroke="currentColor" stroke-width="1.2" stroke-linecap="round"/>
      </svg>
      {i18n.t('nav.today')}
      {#if counts.day > 0}<span class="nav-count">{counts.day}</span>{/if}
    </a>

    <a href="/week"   class="nav-item" onclick={onClose} class:active={currentView === 'week'}>
      <svg class="nav-icon" viewBox="0 0 16 16" fill="none">
        <rect x="1" y="1" width="14" height="14" rx="1" stroke="currentColor" stroke-width="1.2"/>
        <path d="M5.5 1v14M10.5 1v14M1 5.5h14M1 10.5h14" stroke="currentColor" stroke-width="1.2"/>
      </svg>
      {i18n.t('nav.week')}
      {#if counts.week > 0}<span class="nav-count">{counts.week}</span>{/if}
    </a>

    <a href="/month"  class="nav-item" onclick={onClose} class:active={currentView === 'month'}>
      <svg class="nav-icon" viewBox="0 0 16 16" fill="none">
        <rect x="1.5" y="2.5" width="13" height="11" rx="1.5" stroke="currentColor" stroke-width="1.2"/>
        <path d="M5 1.5v2M11 1.5v2M1.5 6h13" stroke="currentColor" stroke-width="1.2" stroke-linecap="round"/>
        <path d="M4 9h2M7 9h2M10 9h2M4 11.5h2M7 11.5h2M10 11.5h2" stroke="currentColor" stroke-width="1.2" stroke-linecap="round"/>
      </svg>
      {i18n.t('nav.month')}
      {#if counts.month > 0}<span class="nav-count">{counts.month}</span>{/if}
    </a>

    <a href="/year"   class="nav-item" onclick={onClose} class:active={currentView === 'year'}>
      <svg class="nav-icon" viewBox="0 0 16 16" fill="none">
        <circle cx="8" cy="8" r="6.5" stroke="currentColor" stroke-width="1.2"/>
        <path d="M8 4v4l2.5 2.5" stroke="currentColor" stroke-width="1.2" stroke-linecap="round" stroke-linejoin="round"/>
      </svg>
      {i18n.t('nav.year')}
      {#if counts.year > 0}<span class="nav-count">{counts.year}</span>{/if}
    </a>
  </div>

  <!-- Records -->
  <div class="nav-section">
    <span class="nav-label">{i18n.t('nav.records')}</span>

    <a href="/backlog" class="nav-item" onclick={onClose} class:active={currentView === 'backlog'}>
      <span class="nav-backlog-dot" class:visible={counts.backlog > 0}></span>
      <svg class="nav-icon" viewBox="0 0 16 16" fill="none">
        <path d="M2 4h12M2 8h8M2 12h5" stroke="currentColor" stroke-width="1.2" stroke-linecap="round"/>
      </svg>
      {i18n.t('nav.backlog')}
      {#if counts.backlog > 0}<span class="nav-count">{counts.backlog}</span>{/if}
    </a>

    <a href="/archive" class="nav-item" onclick={onClose} class:active={currentView === 'archive'}>
      <svg class="nav-icon" viewBox="0 0 16 16" fill="none">
        <rect x="1.5" y="3.5" width="13" height="9" rx="1.5" stroke="currentColor" stroke-width="1.2"/>
        <path d="M1.5 6.5h13" stroke="currentColor" stroke-width="1.2"/>
        <path d="M6 9.5h4" stroke="currentColor" stroke-width="1.2" stroke-linecap="round"/>
      </svg>
      {i18n.t('nav.archive')}
      {#if counts.archive > 0}<span class="nav-count">{counts.archive}</span>{/if}
    </a>

    <a href="/stats" class="nav-item" onclick={onClose} class:active={currentView === 'stats'}>
      <svg class="nav-icon" viewBox="0 0 16 16" fill="none">
        <path d="M2 12V8M6 12V5M10 12V7M14 12V3" stroke="currentColor" stroke-width="1.2" stroke-linecap="round"/>
      </svg>
      {i18n.locale === 'ru' ? 'Статистика' : 'Stats'}
    </a>

    <a href="/notes" class="nav-item" onclick={onClose} class:active={currentView === 'docs'}>
      <svg class="nav-icon" viewBox="0 0 16 16" fill="none">
        <rect x="2.5" y="1.5" width="11" height="13" rx="1.5" stroke="currentColor" stroke-width="1.2"/>
        <path d="M5 5h6M5 8h6M5 11h4" stroke="currentColor" stroke-width="1.2" stroke-linecap="round"/>
      </svg>
      {i18n.locale === 'ru' ? 'Заметки' : 'Notes'}
    </a>

    <a href="/settings" class="nav-item" onclick={onClose} class:active={currentView === 'settings'}>
      <svg class="nav-icon" viewBox="0 0 16 16" fill="none">
        <circle cx="8" cy="8" r="2" stroke="currentColor" stroke-width="1.2"/>
        <path d="M8 1.5v1.2M8 13.3v1.2M1.5 8h1.2M13.3 8h1.2M3.4 3.4l.85.85M11.75 11.75l.85.85M3.4 12.6l.85-.85M11.75 4.25l.85-.85" stroke="currentColor" stroke-width="1.2" stroke-linecap="round"/>
      </svg>
      {i18n.t('nav.settings')}
    </a>
  </div>

  <div class="sidebar-footer">
    <div class="flex items-center gap-2">
      <button class="theme-toggle" onclick={toggleTheme} title={i18n.t('action.toggle_theme')}>
        {#if theme === 'dark'}
          <svg width="12" height="12" viewBox="0 0 16 16" fill="none">
            <circle cx="8" cy="8" r="3.5" stroke="currentColor" stroke-width="1.4"/>
            <path d="M8 1v1.5M8 13.5V15M1 8h1.5M13.5 8H15M3.05 3.05l1.06 1.06M11.89 11.89l1.06 1.06M3.05 12.95l1.06-1.06M11.89 4.11l1.06-1.06" stroke="currentColor" stroke-width="1.4" stroke-linecap="round"/>
          </svg>
        {:else}
          <svg width="12" height="12" viewBox="0 0 16 16" fill="none">
            <path d="M13.5 10A6 6 0 0 1 6 2.5a6 6 0 1 0 7.5 7.5z" stroke="currentColor" stroke-width="1.4" stroke-linejoin="round"/>
          </svg>
        {/if}
      </button>

      <button 
        class="theme-toggle px-2 w-auto font-mono text-[10px] uppercase tracking-wider" 
        onclick={toggleLocale} 
        title={i18n.t('action.change_lang')}
      >
        {i18n.locale}
      </button>
    </div>

    {#if userStore.user?.name}
      <div class="user-card">
        <div class="user-avatar">{userStore.user.name.charAt(0).toUpperCase()}</div>
        <div class="min-w-0 flex-1">
          <div class="user-name truncate">{userStore.user.name}</div>
          {#if userStore.user.email}
            <div class="user-email truncate">{userStore.user.email}</div>
          {/if}
        </div>
        <button class="logout-btn" onclick={logout} title={i18n.locale === 'ru' ? 'Выйти' : 'Log out'}>
          <svg width="14" height="14" viewBox="0 0 16 16" fill="none">
            <path d="M6 2H3a1 1 0 0 0-1 1v10a1 1 0 0 0 1 1h3" stroke="currentColor" stroke-width="1.3" stroke-linecap="round"/>
            <path d="M11 11l3-3-3-3M14 8H6" stroke="currentColor" stroke-width="1.3" stroke-linecap="round" stroke-linejoin="round"/>
          </svg>
        </button>
      </div>
    {/if}
  </div>

</aside>
