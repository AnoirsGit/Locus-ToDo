<script lang="ts">
  import type { TaskView } from '$entities/task'

  type AppView = TaskView | 'settings'

  type Props = { currentView: AppView }
  const { currentView }: Props = $props()

  const nav = [
    { view: 'day'   as AppView, label: 'Сегодня', href: '/today'  },
    { view: 'week'  as AppView, label: 'Неделя',  href: '/week'   },
    { view: 'month' as AppView, label: 'Месяц',   href: '/month'  },
    { view: 'year'  as AppView, label: 'Год',      href: '/year'   },
  ]

  const secondary = [
    { view: 'backlog'  as AppView, label: 'Беклог',   href: '/backlog'  },
    { view: 'archive'  as AppView, label: 'Архив',    href: '/archive'  },
  ]
</script>

<aside class="w-48 border-r border-gray-800 flex flex-col py-4 px-3 gap-1 shrink-0">
  <p class="text-xs font-semibold text-gray-500 px-2 mb-1 uppercase tracking-wide">Цикл</p>

  {#each nav as item}
    <a
      href={item.href}
      class="block px-3 py-2 rounded text-sm transition-colors"
      class:bg-gray-800={currentView === item.view}
      class:text-white={currentView === item.view}
      class:text-gray-400={currentView !== item.view}
    >
      {item.label}
    </a>
  {/each}

  <div class="border-t border-gray-800 my-2"></div>

  {#each secondary as item}
    <a
      href={item.href}
      class="block px-3 py-2 rounded text-sm transition-colors"
      class:bg-gray-800={currentView === item.view}
      class:text-white={currentView === item.view}
      class:text-gray-400={currentView !== item.view}
    >
      {item.label}
    </a>
  {/each}

  <div class="border-t border-gray-800 my-2"></div>

  <a
    href="/settings"
    class="block px-3 py-2 rounded text-sm transition-colors"
    class:bg-gray-800={currentView === 'settings'}
    class:text-white={currentView === 'settings'}
    class:text-gray-400={currentView !== 'settings'}
  >
    Настройки
  </a>
</aside>
