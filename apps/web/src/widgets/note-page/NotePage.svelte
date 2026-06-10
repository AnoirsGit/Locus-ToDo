<script lang="ts">
  import { goto } from '$app/navigation'
  import { NoteTree } from '$widgets/note-tree'
  import { NoteBoard } from '$widgets/note-board'
  import { noteStore } from '$entities/note'
  import { i18n } from '$shared/lib/i18n'

  type Props = { rootId: string | null }
  const { rootId }: Props = $props()

  type NotesView = 'outline' | 'board'
  let view = $state<NotesView>('outline')

  $effect(() => {
    const id = rootId
    noteStore.load().then(() => {
      noteStore.setRoot(id)
      // Deep-link guard: unknown/deleted note id → back to the root page
      if (id && noteStore.breadcrumbs.length === 0) {
        goto('/notes', { replaceState: true })
      }
    })
  })

  const zoomedNode = $derived(rootId ? noteStore.breadcrumbs.at(-1) : undefined)
  const pageTitle = $derived(
    zoomedNode
      ? (zoomedNode.content || 'Untitled')
      : (i18n.locale === 'ru' ? 'Заметки' : 'Notes')
  )

  // Hierarchical "up": parent crumb or the root notes page
  const handleBack = () => {
    const parent = noteStore.breadcrumbs.at(-2)
    goto(parent ? `/notes/${parent.id}` : '/notes')
  }
</script>

<svelte:head>
  <title>{pageTitle} — Locus</title>
</svelte:head>

<div class="notes-page">
  <div class="notes-header">
    <div class="notes-title">
      {#if rootId}
        <button class="notes-back" onclick={handleBack} aria-label="Back">
          <svg width="16" height="16" viewBox="0 0 16 16" fill="none">
            <path d="M10 3L5 8l5 5" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
          </svg>
        </button>
      {/if}
      <h1>{pageTitle}</h1>
    </div>

    <div class="notes-view-toggle">
      <button
        class="notes-view-btn"
        class:active={view === 'outline'}
        onclick={() => view = 'outline'}
        title="Outline view"
      >
        <svg width="14" height="14" viewBox="0 0 14 14" fill="none">
          <path d="M2 3h10M2 7h7M2 11h5" stroke="currentColor" stroke-width="1.3" stroke-linecap="round"/>
        </svg>
        {i18n.locale === 'ru' ? 'Список' : 'List'}
      </button>

      <button
        class="notes-view-btn"
        class:active={view === 'board'}
        onclick={() => view = 'board'}
        title="Board view"
      >
        <svg width="14" height="14" viewBox="0 0 14 14" fill="none">
          <rect x="1" y="1" width="4" height="12" rx="1" stroke="currentColor" stroke-width="1.3"/>
          <rect x="5.5" y="1" width="3" height="8" rx="1" stroke="currentColor" stroke-width="1.3"/>
          <rect x="9" y="1" width="4" height="10" rx="1" stroke="currentColor" stroke-width="1.3"/>
        </svg>
        {i18n.locale === 'ru' ? 'Доска' : 'Board'}
      </button>
    </div>
  </div>

  <div class="notes-body">
    {#if view === 'outline'}
      <NoteTree />
    {:else}
      <NoteBoard />
    {/if}
  </div>
</div>

<style>
  .notes-page {
    display: flex;
    flex-direction: column;
    height: 100%;
    padding: 24px 28px;
    gap: 20px;
    overflow: hidden;
  }

  .notes-header {
    display: flex;
    align-items: center;
    justify-content: space-between;
    flex-shrink: 0;
  }

  .notes-title {
    display: flex;
    align-items: center;
    gap: 8px;
    min-width: 0;
  }

  .notes-title h1 {
    font-family: var(--font-display);
    font-size: 22px;
    font-weight: 500;
    font-style: italic;
    color: var(--color-text-strong);
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
  }

  .notes-back {
    display: flex;
    align-items: center;
    justify-content: center;
    width: 28px;
    height: 28px;
    flex-shrink: 0;
    border: 1px solid var(--color-border);
    border-radius: var(--radius);
    background: var(--color-surface);
    color: var(--color-muted);
    cursor: pointer;
    transition: color 120ms, background 120ms;
  }

  .notes-back:hover {
    color: var(--color-text);
    background: var(--color-card);
  }

  .notes-view-toggle {
    display: flex;
    gap: 2px;
    background: var(--color-surface);
    border: 1px solid var(--color-border);
    border-radius: var(--radius);
    padding: 2px;
  }

  .notes-view-btn {
    display: flex;
    align-items: center;
    gap: 5px;
    padding: 4px 10px;
    border-radius: 3px;
    font-size: 12px;
    color: var(--color-muted);
    background: transparent;
    border: none;
    cursor: pointer;
    transition: background 120ms, color 120ms;
  }

  .notes-view-btn:hover {
    color: var(--color-text);
  }

  .notes-view-btn.active {
    background: var(--color-card);
    color: var(--color-text);
    box-shadow: 0 1px 2px rgba(0,0,0,0.06);
  }

  .notes-body {
    flex: 1;
    overflow-y: auto;
    overflow-x: hidden;
  }

  /* Board overflows horizontally */
  :global(.note-board) ~ .notes-body,
  .notes-body:has(:global(.note-board)) {
    overflow-x: auto;
  }
</style>
