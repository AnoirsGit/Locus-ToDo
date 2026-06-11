<script lang="ts">
  import { goto } from '$app/navigation'
  import { noteStore } from '$entities/note'
  import type { NoteNode } from '$entities/note'
  import { tagStore, NoteTagFilterBar } from '$entities/tag'
  import NoteRow from './NoteRow.svelte'

  let focusId = $state<string | null>(null)
  let anchorId = $state<string | null>(null) // range selection anchor

  $effect(() => {
    noteStore.load()
    tagStore.load()
    tagStore.loadNoteAssignments()
  })

  // When a tag filter is active, prune the tree to branches that contain a
  // match (matching node or an ancestor of one), force-expanding along the way.
  const pruneByTag = (nodes: NoteNode[]): NoteNode[] =>
    nodes
      .map(n => ({ ...n, collapsed: false, children: pruneByTag(n.children) }))
      .filter(n => tagStore.noteMatchesFilter(n.id) || n.children.length > 0)

  const visibleRoots = $derived(
    tagStore.isFilteringNotes ? pruneByTag(noteStore.rootNodes) : noteStore.rootNodes
  )

  const handleFocusChange = (id: string | null) => {
    focusId = id
  }

  const handleAddRoot = async () => {
    const node = await noteStore.addRoot()
    focusId = node.id
  }

  // Called by NoteRow on ArrowUp/ArrowDown
  const handleFocusMove = (fromId: string, dir: 'up' | 'down') => {
    const flat = noteStore.flat
    const idx = flat.findIndex(f => f.node.id === fromId)
    const target = dir === 'up' ? flat[idx - 1] : flat[idx + 1]
    if (target) focusId = target.node.id
  }

  // Called by NoteRow on Shift+Arrow
  const handleSelectExtend = (fromId: string, dir: 'up' | 'down') => {
    const flat = noteStore.flat
    const idx = flat.findIndex(f => f.node.id === fromId)
    const target = dir === 'up' ? flat[idx - 1] : flat[idx + 1]
    if (!target) return

    const newSel = new Set(noteStore.selectedIds)
    if (newSel.has(target.node.id)) {
      // Shrink — deselect the current end
      newSel.delete(fromId)
    } else {
      newSel.add(fromId)
      newSel.add(target.node.id)
    }
    noteStore.setSelection(newSel)
    focusId = target.node.id
  }

  // Called by NoteRow on click (for selection)
  const handleSelect = (id: string, shift: boolean, ctrl: boolean) => {
    const flat = noteStore.flat

    if (shift && anchorId) {
      // Range select from anchor to id
      const a = flat.findIndex(f => f.node.id === anchorId)
      const b = flat.findIndex(f => f.node.id === id)
      const [start, end] = a <= b ? [a, b] : [b, a]
      noteStore.setSelection(new Set(flat.slice(start, end + 1).map(f => f.node.id)))
    } else if (ctrl) {
      // Toggle individual
      const newSel = new Set(noteStore.selectedIds)
      if (newSel.has(id)) newSel.delete(id)
      else newSel.add(id)
      noteStore.setSelection(newSel)
      anchorId = id
    } else {
      // Single select
      noteStore.setSelection(new Set([id]))
      anchorId = id
    }
  }

  const handleClearSelection = () => {
    noteStore.clearSelection()
    anchorId = null
    confirmDelete = false
  }

  let confirmDelete = $state(false)

  const handleDeleteSelected = () => {
    if (confirmDelete) {
      noteStore.deleteSelected()
      confirmDelete = false
    } else {
      confirmDelete = true
      // Auto-reset after 3s if user doesn't confirm
      setTimeout(() => { confirmDelete = false }, 3000)
    }
  }

  const crumbs = $derived(noteStore.breadcrumbs)
  const selCount = $derived(noteStore.selectedIds.size)
</script>

<div class="note-tree-wrap">

  <!-- Breadcrumb navigation -->
  {#if noteStore.rootId}
    <nav class="note-breadcrumb">
      <button class="note-crumb note-crumb-home" onclick={() => goto('/notes')}>
        <svg width="12" height="12" viewBox="0 0 12 12" fill="none">
          <path d="M1 6L6 1.5L11 6V11H7.5V8H4.5V11H1V6Z" stroke="currentColor" stroke-width="1.2" stroke-linejoin="round"/>
        </svg>
        Notes
      </button>
      {#each crumbs as crumb, i}
        <span class="note-crumb-sep">›</span>
        {#if i < crumbs.length - 1}
          <button class="note-crumb" onclick={() => goto(`/notes/${crumb.id}`)}>
            {crumb.content || 'Untitled'}
          </button>
        {:else}
          <span class="note-crumb note-crumb-current">{crumb.content || 'Untitled'}</span>
        {/if}
      {/each}
    </nav>
  {/if}

  <!-- Selection toolbar (only for multi-select; single-select shows inline delete on the row) -->
  {#if selCount > 1}
    <div class="note-selection-bar">
      <span class="note-sel-count">{selCount} selected</span>
      <button class="note-sel-action" class:confirming={confirmDelete} onclick={handleDeleteSelected}>
        <svg width="12" height="12" viewBox="0 0 12 12" fill="none">
          <path d="M2 3h8M5 3V2h2v1M4.5 3v6M6 3v6M7.5 3v6M3 3l.5 7h5L9 3" stroke="currentColor" stroke-width="1.2" stroke-linecap="round" stroke-linejoin="round"/>
        </svg>
        {confirmDelete ? 'Confirm?' : 'Delete'}
      </button>
      <button class="note-sel-clear" onclick={handleClearSelection}>✕</button>
    </div>
  {/if}

  <!-- Tag filter -->
  <NoteTagFilterBar />

  <!-- Note tree -->
  <div class="note-tree" role="tree">
    {#each visibleRoots as node (node.id)}
      <NoteRow
        {node}
        depth={0}
        {focusId}
        onFocusChange={handleFocusChange}
        onFocusMove={handleFocusMove}
        onSelectExtend={handleSelectExtend}
        onSelect={handleSelect}
        onZoom={(id) => goto(`/notes/${id}`)}
      />
    {/each}

    {#if noteStore.loaded && visibleRoots.length === 0}
      <div class="note-empty">
        <svg width="32" height="32" viewBox="0 0 32 32" fill="none" opacity="0.35">
          <rect x="5" y="4" width="22" height="24" rx="3" stroke="currentColor" stroke-width="1.5"/>
          <path d="M10 11h12M10 16h8M10 21h6" stroke="currentColor" stroke-width="1.5" stroke-linecap="round"/>
        </svg>
        <span>No notes yet</span>
      </div>
    {/if}

    <button class="note-add-root" onclick={handleAddRoot}>
      <svg width="12" height="12" viewBox="0 0 12 12" fill="none">
        <path d="M6 1v10M1 6h10" stroke="currentColor" stroke-width="1.5" stroke-linecap="round"/>
      </svg>
      Add note
    </button>
  </div>

</div>

<style>
  .note-tree-wrap {
    display: flex;
    flex-direction: column;
    height: 100%;
    gap: 0;
  }

  /* ── Breadcrumb ─────────────────────────────────────────────────── */

  .note-breadcrumb {
    display: flex;
    align-items: center;
    gap: 4px;
    padding: 8px 0 12px;
    border-bottom: 1px solid var(--color-border);
    margin-bottom: 8px;
    flex-wrap: wrap;
  }

  .note-crumb {
    font-size: 12px;
    color: var(--color-muted);
    background: none;
    border: none;
    cursor: pointer;
    padding: 2px 4px;
    border-radius: 3px;
    transition: color 100ms, background 100ms;
    display: flex;
    align-items: center;
    gap: 4px;
  }

  .note-crumb:hover { color: var(--color-text); background: var(--color-surface-2); }

  .note-crumb-home { font-weight: 500; }

  .note-crumb-current {
    font-size: 12px;
    color: var(--color-text-strong);
    font-weight: 600;
    padding: 2px 4px;
  }

  .note-crumb-sep {
    font-size: 11px;
    color: var(--color-muted-2);
    user-select: none;
  }

  /* ── Selection bar ───────────────────────────────────────────────── */

  .note-selection-bar {
    display: flex;
    align-items: center;
    gap: 8px;
    padding: 6px 10px;
    background: var(--color-brand-soft);
    border: 1px solid color-mix(in srgb, var(--color-brand) 25%, transparent);
    border-radius: var(--radius);
    margin-bottom: 8px;
  }

  .note-sel-count {
    font-size: 12px;
    font-weight: 600;
    font-family: var(--font-mono);
    color: var(--color-brand-2);
    flex: 1;
  }

  .note-sel-action {
    display: flex;
    align-items: center;
    gap: 4px;
    font-size: 12px;
    color: var(--color-danger);
    background: none;
    border: none;
    cursor: pointer;
    padding: 2px 6px;
    border-radius: 3px;
    transition: background 100ms;
  }

  .note-sel-action:hover { background: color-mix(in srgb, var(--color-danger) 10%, transparent); }

  .note-sel-action.confirming {
    background: color-mix(in srgb, var(--color-danger) 15%, transparent);
    font-weight: 600;
  }

  .note-sel-clear {
    font-size: 11px;
    color: var(--color-muted);
    background: none;
    border: none;
    cursor: pointer;
    padding: 2px 4px;
    border-radius: 3px;
    transition: color 100ms;
  }

  .note-sel-clear:hover { color: var(--color-text); }

  /* ── Empty state ─────────────────────────────────────────────────── */

  .note-empty {
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 10px;
    padding: 48px 0 32px;
    color: var(--color-muted);
  }

  .note-empty span {
    font-size: 13px;
  }
</style>
