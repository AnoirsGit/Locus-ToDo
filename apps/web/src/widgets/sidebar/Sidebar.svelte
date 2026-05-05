<script lang="ts">
  import type { TaskView } from '$entities/task'
  import { userStore } from '$entities/user'
  import { onMount } from 'svelte'

  type AppView = TaskView | 'settings'
  type Props = { currentView: AppView }
  const { currentView }: Props = $props()

  const nav = [
    { view: 'day'   as AppView, label: 'Сегодня', href: '/today'  },
    { view: 'week'  as AppView, label: 'Неделя',  href: '/week'   },
    { view: 'month' as AppView, label: 'Месяц',   href: '/month'  },
    { view: 'year'  as AppView, label: 'Год',     href: '/year'   },
  ]

  const secondary = [
    { view: 'backlog' as AppView, label: 'Беклог',  href: '/backlog'  },
    { view: 'archive' as AppView, label: 'Архив',   href: '/archive'  },
  ]

  const userInitial = $derived(userStore.user?.name?.charAt(0)?.toUpperCase() ?? 'Л')
  const userName    = $derived(userStore.user?.name ?? '')
  const userEmail   = $derived(userStore.user?.email ?? '')

  let theme = $state<'light' | 'dark'>('dark')

  onMount(() => {
    theme = (localStorage.getItem('theme') as 'light' | 'dark') || 'dark'
  })

  const toggleTheme = () => {
    theme = theme === 'dark' ? 'light' : 'dark'
    document.documentElement.dataset.theme = theme
    localStorage.setItem('theme', theme)
  }
</script>

<aside class="sidebar">
  <!-- Brand -->
  <div class="brand">
    <div class="brand-logo">L</div>
    <span class="brand-mark">Locus</span>
    <span class="brand-dot"></span>
  </div>

  <!-- Horizons nav -->
  <div class="nav-section">
    <span class="nav-label">Горизонты</span>
    {#each nav as item}
      <a
        href={item.href}
        class="nav-item"
        class:active={currentView === item.view}
      >{item.label}</a>
    {/each}
  </div>

  <!-- Records nav -->
  <div class="nav-section">
    <span class="nav-label">Записи</span>
    {#each secondary as item}
      <a
        href={item.href}
        class="nav-item"
        class:active={currentView === item.view}
      >{item.label}</a>
    {/each}
    <a
      href="/settings"
      class="nav-item"
      class:active={currentView === 'settings'}
    >Настройки</a>
  </div>

  <!-- Theme toggle -->
  <button class="theme-toggle" onclick={toggleTheme}>
    {#if theme === 'dark'}
      <svg width="13" height="13" viewBox="0 0 16 16" fill="none">
        <circle cx="8" cy="8" r="3.5" stroke="currentColor" stroke-width="1.4"/>
        <path d="M8 1v1.5M8 13.5V15M1 8h1.5M13.5 8H15M3.05 3.05l1.06 1.06M11.89 11.89l1.06 1.06M3.05 12.95l1.06-1.06M11.89 4.11l1.06-1.06" stroke="currentColor" stroke-width="1.4" stroke-linecap="round"/>
      </svg>
      Светлая тема
    {:else}
      <svg width="13" height="13" viewBox="0 0 16 16" fill="none">
        <path d="M13.5 10A6 6 0 0 1 6 2.5a6 6 0 1 0 7.5 7.5z" stroke="currentColor" stroke-width="1.4" stroke-linejoin="round"/>
      </svg>
      Тёмная тема
    {/if}
  </button>

  <!-- User card -->
  {#if userName}
    <div class="user-card">
      <div class="user-avatar">{userInitial}</div>
      <div class="min-w-0">
        <div class="user-name truncate">{userName}</div>
        {#if userEmail}
          <div class="user-email truncate">{userEmail}</div>
        {/if}
      </div>
    </div>
  {/if}
</aside>
