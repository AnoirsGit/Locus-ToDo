<script lang="ts">
  import type { Snippet } from 'svelte'
  import { TaskCard } from '$entities/task'
  import type { TaskWithPeriod } from '$entities/task'
  import { tagStore } from '$entities/tag'
  import { sectionPrefs } from '$shared/lib/sectionPrefs.svelte'

  let {
    title,
    tasks,
    onToggle,
    onEdit,
    footer,
    storageKey = '',
    compact = false,
  } = $props<{
    title: string
    tasks: TaskWithPeriod[]
    onToggle: (id: string) => void
    onEdit?: (task: TaskWithPeriod) => void
    footer?: Snippet
    storageKey?: string
    compact?: boolean
  }>()

  const collapsible = $derived(storageKey !== '')
  const open = $derived(!collapsible || sectionPrefs.isOpen(storageKey))

  function toggle() {
    if (collapsible) sectionPrefs.toggle(storageKey)
  }
</script>

<section class="section">
  <div
    class="section-header"
    class:collapsible
    onclick={toggle}
    role={collapsible ? 'button' : undefined}
    tabindex={collapsible ? 0 : undefined}
    onkeydown={(e) => { if (collapsible && (e.key === 'Enter' || e.key === ' ')) toggle() }}
    aria-expanded={collapsible ? open : undefined}
  >
    <h2 class="section-title">{title}</h2>
    <div class="section-header-right">
      <span class="section-meta">{tasks.length}</span>
      {#if collapsible}
        <svg
          class="section-chevron"
          class:open
          width="14" height="14" viewBox="0 0 14 14" fill="none"
        >
          <path d="M3 5l4 4 4-4" stroke="currentColor" stroke-width="1.5"
            stroke-linecap="round" stroke-linejoin="round"/>
        </svg>
      {/if}
    </div>
  </div>

  <div class="section-body" class:collapsed={!open}>
    <div class="section-body-inner">
      <div class="task-list cards" class:compact>
        {#each tasks as task (task.period.id)}
          <TaskCard {task} onToggle={onToggle} onEdit={onEdit} tags={tagStore.getTagsForTask(task.id)} />
        {/each}
        {@render footer?.()}
      </div>
    </div>
  </div>
</section>

<style>
  .section-header.collapsible {
    cursor: pointer;
    user-select: none;
  }
  .section-header.collapsible:hover .section-title {
    color: var(--color-text-strong);
  }

  .section-header-right {
    display: flex;
    align-items: center;
    gap: 8px;
  }

  .section-chevron {
    color: var(--color-muted-2);
    transition: transform 0.2s ease;
    flex-shrink: 0;
  }
  .section-chevron.open {
    transform: rotate(0deg);
  }
  .section-chevron:not(.open) {
    transform: rotate(-90deg);
  }

  /* Animate collapse via grid trick */
  .section-body {
    display: grid;
    grid-template-rows: 1fr;
    transition: grid-template-rows 0.22s ease;
    overflow: hidden;
  }
  .section-body.collapsed {
    grid-template-rows: 0fr;
  }
  .section-body-inner {
    overflow: hidden;
    min-height: 0;
  }
</style>
