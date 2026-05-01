<script lang="ts">
  import type { TaskView } from '@locus/shared'

  type Props = { currentView: TaskView }
  let { currentView = $bindable() }: Props = $props()

  const views: { label: string; value: TaskView; icon: string }[] = [
    { label: 'День', value: 'day', icon: '☀️' },
    { label: 'Неделя', value: 'week', icon: '📅' },
    { label: 'Месяц', value: 'month', icon: '🗓️' },
    { label: 'Год', value: 'year', icon: '🎯' },
    { label: 'Бэклог', value: 'backlog', icon: '📦' },
    { label: 'Архив', value: 'archive', icon: '🗄️' },
  ]
</script>

<aside>
  <div class="logo">Цикл</div>
  <nav>
    {#each views as view}
      <button
        class:active={currentView === view.value}
        onclick={() => (currentView = view.value)}
      >
        <span class="icon">{view.icon}</span>
        <span>{view.label}</span>
      </button>
    {/each}
  </nav>
</aside>

<style>
  aside {
    width: 220px;
    min-height: 100vh;
    background: var(--color-surface);
    border-right: 1px solid var(--color-border);
    display: flex;
    flex-direction: column;
    padding: 24px 16px;
    gap: 32px;
    flex-shrink: 0;
  }

  .logo {
    font-size: 1.4rem;
    font-weight: 700;
    color: var(--color-accent);
    letter-spacing: -0.5px;
    padding: 0 8px;
  }

  nav {
    display: flex;
    flex-direction: column;
    gap: 4px;
  }

  button {
    display: flex;
    align-items: center;
    gap: 10px;
    padding: 10px 12px;
    border-radius: var(--radius);
    color: var(--color-text-muted);
    font-size: 0.9rem;
    transition: all 0.15s;
    width: 100%;
    text-align: left;
  }

  button:hover {
    background: var(--color-surface-2);
    color: var(--color-text);
  }

  button.active {
    background: var(--color-surface-2);
    color: var(--color-text);
    font-weight: 500;
  }

  .icon {
    font-size: 1rem;
  }
</style>
