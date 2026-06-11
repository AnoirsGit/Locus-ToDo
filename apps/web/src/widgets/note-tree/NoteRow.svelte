<script lang="ts">
  import type { NoteNode } from '$entities/note'
  import { noteStore } from '$entities/note'
  import { tagStore, TagChip } from '$entities/tag'
  import NoteRowMenu from './NoteRowMenu.svelte'

  type Props = {
    node: NoteNode
    depth: number
    focusId: string | null
    onFocusChange: (id: string | null) => void
    onFocusMove: (id: string, dir: 'up' | 'down') => void
    onSelectExtend: (id: string, dir: 'up' | 'down') => void
    onSelect: (id: string, shift: boolean, ctrl: boolean) => void
    onZoom: (id: string) => void
  }
  const { node, depth, focusId, onFocusChange, onFocusMove, onSelectExtend, onSelect, onZoom }: Props = $props()

  let inputEl = $state<HTMLElement | null>(null)
  let menuOpen = $state(false)
  let dropPos = $state<'before' | 'after' | 'child' | null>(null)

  const selected = $derived(noteStore.selectedIds.has(node.id))

  $effect(() => {
    if (focusId === node.id && inputEl) {
      inputEl.focus()
      if (inputEl instanceof HTMLInputElement || inputEl instanceof HTMLTextAreaElement) {
        const len = inputEl.value.length
        inputEl.setSelectionRange(len, len)
      }
    }
  })

  // When entire text is selected in the input → add this node to selection
  const handleTextSelect = (e: Event) => {
    const input = e.target as HTMLInputElement
    const fullySelected =
      input.value.length > 0 &&
      input.selectionStart === 0 &&
      input.selectionEnd === input.value.length

    const inSel = noteStore.selectedIds.has(node.id)
    if (fullySelected && !inSel) {
      const next = new Set(noteStore.selectedIds)
      next.add(node.id)
      noteStore.setSelection(next)
    } else if (!fullySelected && inSel) {
      const next = new Set(noteStore.selectedIds)
      next.delete(node.id)
      noteStore.setSelection(next)
    }
  }

  const handleKeydown = (e: KeyboardEvent) => {
    // Ctrl/Cmd+. opens the row actions menu (Workflowy muscle memory).
    if (e.key === '.' && (e.ctrlKey || e.metaKey)) {
      e.preventDefault()
      menuOpen = true
      return
    }

    if (e.key === 'ArrowUp' || e.key === 'ArrowDown') {
      const dir = e.key === 'ArrowUp' ? 'up' : 'down'
      if (e.shiftKey) {
        e.preventDefault()
        onSelectExtend(node.id, dir)
      } else {
        e.preventDefault()
        onFocusMove(node.id, dir)
      }
      return
    }

    if (e.key === 'Escape') {
      noteStore.clearSelection()
      return
    }

    // Delete selected nodes (not just text): multi-selection, or this row's
    // text fully selected. Plain click-to-edit keeps normal text editing.
    if (e.key === 'Delete' || e.key === 'Backspace') {
      const input = e.target as HTMLInputElement
      const fullySelected =
        input.value.length > 0 &&
        input.selectionStart === 0 &&
        input.selectionEnd === input.value.length
      const inSelection = noteStore.selectedIds.has(node.id)
      if (inSelection && (noteStore.selectedIds.size > 1 || fullySelected)) {
        e.preventDefault()
        noteStore.deleteSelected()
        onFocusChange(null)
        return
      }
    }

    if (e.key === 'Enter') {
      e.preventDefault()
      noteStore.addAfter(node.id).then(newNode => onFocusChange(newNode.id))
    }

    if (e.key === 'Backspace' && node.content === '') {
      e.preventDefault()
      noteStore.remove(node.id).then(focusTarget => onFocusChange(focusTarget))
    }

    if (e.key === 'Tab') {
      e.preventDefault()
      if (e.shiftKey) {
        noteStore.unindent(node.id)
      } else {
        noteStore.indent(node.id)
      }
      onFocusChange(node.id)
    }
  }

  const handleRowClick = (e: MouseEvent) => {
    onSelect(node.id, e.shiftKey, e.ctrlKey || e.metaKey)
  }

  const handleBulletClick = (e: MouseEvent) => {
    e.stopPropagation()
    if (hasChildren) {
      noteStore.toggleCollapse(node.id)
    } else {
      onZoom(node.id)
    }
  }

  const handleContextMenu = (e: MouseEvent) => {
    e.preventDefault()
    menuOpen = true
  }

  // ── Drag and drop ───────────────────────────────────────────────────────────
  const handleDragOver = (e: DragEvent) => {
    const dragId = noteStore.dragId
    if (!dragId || dragId === node.id) return
    e.preventDefault()
    const rect = (e.currentTarget as HTMLElement).getBoundingClientRect()
    const y = e.clientY - rect.top
    dropPos = y < rect.height * 0.25 ? 'before' : y > rect.height * 0.75 ? 'after' : 'child'
  }

  const handleDrop = (e: DragEvent) => {
    const dragId = noteStore.dragId
    if (dragId && dropPos) {
      e.preventDefault()
      noteStore.dropNode(dragId, node.id, dropPos)
    }
    dropPos = null
    noteStore.setDrag(null)
  }

  const hasChildren = $derived(node.children.length > 0)
  const indentPx = $derived(depth * 24)
  const tags = $derived(tagStore.getTagsForNote(node.id))
</script>

<div
  class="note-row"
  class:selected
  class:menu-open={menuOpen}
  class:drop-before={dropPos === 'before'}
  class:drop-after={dropPos === 'after'}
  class:drop-child={dropPos === 'child'}
  style:padding-left="{indentPx}px"
  onclick={handleRowClick}
  oncontextmenu={handleContextMenu}
  ondragover={handleDragOver}
  ondragleave={() => dropPos = null}
  ondrop={handleDrop}
  role="treeitem"
  aria-selected={selected}
>

  <!-- Drag handle -->
  <span
    class="note-drag-handle"
    draggable="true"
    ondragstart={(e) => { noteStore.setDrag(node.id); e.dataTransfer?.setData('text/plain', node.id) }}
    ondragend={() => { noteStore.setDrag(null); dropPos = null }}
    aria-hidden="true"
    title="Drag to move"
  >⠿</span>

  <!-- Collapse toggle / bullet -->
  <button
    class="note-bullet"
    class:has-children={hasChildren}
    class:collapsed={node.collapsed}
    onclick={handleBulletClick}
    tabindex="-1"
    aria-label={hasChildren ? (node.collapsed ? 'Expand' : 'Collapse') : 'Zoom in'}
  >
    {#if hasChildren}
      <svg width="8" height="8" viewBox="0 0 8 8" fill="currentColor">
        {#if node.collapsed}
          <polygon points="2,1 7,4 2,7"/>
        {:else}
          <polygon points="1,2 7,2 4,7"/>
        {/if}
      </svg>
    {:else}
      <span class="note-dot"></span>
    {/if}
  </button>

  <!-- Content -->
  <div class="note-content">

    {#if node.type === 'image'}
      <div class="note-image-wrap">
        {#if node.url}
          <img src={node.url} alt={node.content} class="note-image" />
        {/if}
        <input
          class="note-input note-image-caption"
          value={node.content}
          placeholder="Image caption"
          oninput={(e) => noteStore.update(node.id, { content: (e.target as HTMLInputElement).value })}
          onkeydown={handleKeydown}
          onselect={handleTextSelect}
          onfocus={() => onFocusChange(node.id)}
          bind:this={inputEl}
        />
      </div>

    {:else if node.type === 'todo'}
      <div class="note-todo-wrap">
        <input
          type="checkbox"
          class="note-todo-check"
          checked={node.done ?? false}
          onclick={(e) => e.stopPropagation()}
          onchange={(e) => noteStore.update(node.id, { done: (e.target as HTMLInputElement).checked })}
        />
        <input
          class="note-input note-todo-label"
          class:done={node.done}
          value={node.content}
          placeholder="To-do…"
          oninput={(e) => noteStore.update(node.id, { content: (e.target as HTMLInputElement).value })}
          onkeydown={handleKeydown}
          onselect={handleTextSelect}
          onfocus={() => onFocusChange(node.id)}
          bind:this={inputEl}
        />
      </div>

    {:else if node.type === 'link'}
      <div class="note-link-wrap">
        <input
          class="note-input note-link-label"
          value={node.content}
          placeholder="Link label"
          oninput={(e) => noteStore.update(node.id, { content: (e.target as HTMLInputElement).value })}
          onkeydown={handleKeydown}
          onselect={handleTextSelect}
          onfocus={() => onFocusChange(node.id)}
          bind:this={inputEl}
        />
        {#if node.url}
          <a href={node.url} target="_blank" rel="noopener" class="note-link-href">↗</a>
        {/if}
      </div>

    {:else}
      <input
        class="note-input"
        class:note-h1={node.type === 'heading1'}
        class:note-h2={node.type === 'heading2'}
        class:note-bullet-input={node.type === 'bullet'}
        value={node.content}
        placeholder={node.type === 'heading1' ? 'Heading' : node.type === 'heading2' ? 'Subheading' : 'Note…'}
        oninput={(e) => noteStore.update(node.id, { content: (e.target as HTMLInputElement).value })}
        onkeydown={handleKeydown}
        onselect={handleTextSelect}
        onfocus={() => onFocusChange(node.id)}
        bind:this={inputEl}
      />
    {/if}

    {#if tags.length > 0}
      <div class="note-tags">
        {#each tags as tag (tag.id)}
          <TagChip {tag} />
        {/each}
      </div>
    {/if}

  </div>

  <!-- Actions menu trigger (hover/focus revealed) -->
  <button
    class="note-row-menu-btn"
    onclick={(e) => { e.stopPropagation(); menuOpen = !menuOpen }}
    tabindex="-1"
    aria-label="Note actions"
  >
    <svg width="14" height="14" viewBox="0 0 14 14" fill="currentColor">
      <circle cx="3" cy="7" r="1.1"/><circle cx="7" cy="7" r="1.1"/><circle cx="11" cy="7" r="1.1"/>
    </svg>
  </button>

  {#if menuOpen}
    <NoteRowMenu {node} onClose={() => menuOpen = false} {onFocusChange} />
  {/if}
</div>

<!-- Children -->
{#if !node.collapsed && node.children.length > 0}
  {#each node.children as child (child.id)}
    <svelte:self
      node={child}
      depth={depth + 1}
      {focusId}
      {onFocusChange}
      {onFocusMove}
      {onSelectExtend}
      {onSelect}
      {onZoom}
    />
  {/each}
{/if}

<style>
  .note-row {
    position: relative;
  }

  .note-drag-handle {
    position: absolute;
    left: -14px;
    top: 50%;
    transform: translateY(-50%);
    font-size: 11px;
    line-height: 1;
    color: var(--color-muted-2);
    cursor: grab;
    opacity: 0;
    transition: opacity 100ms;
    user-select: none;
  }

  .note-row:hover .note-drag-handle { opacity: 1; }
  .note-drag-handle:active { cursor: grabbing; }

  .note-row.drop-before { box-shadow: inset 0 2px 0 var(--color-brand); }
  .note-row.drop-after  { box-shadow: inset 0 -2px 0 var(--color-brand); }
  .note-row.drop-child {
    background: var(--color-brand-soft);
    border-radius: var(--radius);
    box-shadow: inset 0 0 0 1px var(--color-brand);
  }

  .note-tags {
    display: flex;
    flex-wrap: wrap;
    gap: 4px;
    padding: 1px 0 3px;
  }

  .note-todo-wrap {
    display: flex;
    align-items: center;
    gap: 8px;
  }

  .note-todo-check {
    flex-shrink: 0;
    width: 14px;
    height: 14px;
    cursor: pointer;
    accent-color: var(--color-brand);
  }

  .note-todo-label.done {
    text-decoration: line-through;
    color: var(--color-muted);
  }

  .note-row.selected {
    background: var(--color-brand-soft);
    border-radius: var(--radius);
  }

  .note-row.selected .note-input {
    background: transparent;
  }

  .note-row-menu-btn {
    position: absolute;
    right: 6px;
    top: 50%;
    transform: translateY(-50%);
    display: flex;
    align-items: center;
    justify-content: center;
    width: 22px;
    height: 22px;
    border-radius: 4px;
    background: none;
    border: none;
    cursor: pointer;
    color: var(--color-muted);
    opacity: 0;
    transition: opacity 100ms, background 100ms;
  }

  .note-row:hover .note-row-menu-btn,
  .note-row:focus-within .note-row-menu-btn,
  .note-row.menu-open .note-row-menu-btn {
    opacity: 1;
  }

  .note-row-menu-btn:hover {
    color: var(--color-text);
    background: var(--color-surface-2);
  }
</style>
