<script lang="ts">
  import type { NoteNode } from '$entities/note'
  import { noteStore } from '$entities/note'

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
  let urlInputEl = $state<HTMLInputElement | null>(null)
  let showUrlInput = $state(false)

  const selected = $derived(noteStore.selectedIds.has(node.id))
  const singleSelected = $derived(selected && noteStore.selectedIds.size === 1)

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

  const handleDeleteClick = (e: MouseEvent) => {
    e.stopPropagation()
    noteStore.remove(node.id).then(focusTarget => onFocusChange(focusTarget))
  }

  const hasChildren = $derived(node.children.length > 0)
  const indentPx = $derived(depth * 24)
</script>

<div
  class="note-row"
  class:selected
  style:padding-left="{indentPx}px"
  onclick={handleRowClick}
  role="treeitem"
  aria-selected={selected}
>

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
        <button class="note-url-toggle" onclick={() => showUrlInput = !showUrlInput} tabindex="-1">
          {showUrlInput ? 'Hide URL' : 'Set URL'}
        </button>
        {#if showUrlInput}
          <input
            class="note-input note-url-input"
            value={node.url ?? ''}
            placeholder="https://..."
            oninput={(e) => noteStore.update(node.id, { url: (e.target as HTMLInputElement).value })}
            bind:this={urlInputEl}
          />
        {/if}
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
        <button class="note-url-toggle" onclick={() => showUrlInput = !showUrlInput} tabindex="-1">
          {showUrlInput ? 'Hide URL' : 'Set URL'}
        </button>
        {#if showUrlInput}
          <input
            class="note-input note-url-input"
            value={node.url ?? ''}
            placeholder="https://..."
            oninput={(e) => noteStore.update(node.id, { url: (e.target as HTMLInputElement).value })}
            bind:this={urlInputEl}
          />
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

    <!-- Type selector (shown on focus, hidden when selected for toolbar clarity) -->
    {#if focusId === node.id && !selected}
      <select
        class="note-type-select"
        value={node.type}
        onchange={(e) => noteStore.update(node.id, { type: (e.target as HTMLSelectElement).value as any })}
        tabindex="-1"
      >
        <option value="text">Text</option>
        <option value="heading1">H1</option>
        <option value="heading2">H2</option>
        <option value="bullet">Bullet</option>
        <option value="image">Image</option>
        <option value="link">Link</option>
      </select>
    {/if}
  </div>

  <!-- Single-select inline delete -->
  {#if singleSelected}
    <button class="note-row-delete" onclick={handleDeleteClick} tabindex="-1" aria-label="Delete note">
      <svg width="13" height="13" viewBox="0 0 12 12" fill="none">
        <path d="M2 3h8M5 3V2h2v1M4.5 3v6M6 3v6M7.5 3v6M3 3l.5 7h5L9 3"
          stroke="currentColor" stroke-width="1.2" stroke-linecap="round" stroke-linejoin="round"/>
      </svg>
    </button>
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

  .note-row.selected {
    background: var(--color-brand-soft);
    border-radius: var(--radius);
  }

  .note-row.selected .note-input {
    background: transparent;
  }

  .note-row-delete {
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
    color: var(--color-danger);
    opacity: 0.7;
    transition: opacity 100ms, background 100ms;
  }

  .note-row-delete:hover {
    opacity: 1;
    background: color-mix(in srgb, var(--color-danger) 10%, transparent);
  }
</style>
