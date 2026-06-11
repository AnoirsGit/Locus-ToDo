<script lang="ts">
  import { goto } from '$app/navigation'
  import type { NoteNode, NoteNodeType } from '$entities/note'
  import { noteStore } from '$entities/note'

  type Props = {
    node: NoteNode
    onClose: () => void
    onFocusChange: (id: string | null) => void
  }
  const { node, onClose, onFocusChange }: Props = $props()

  let menuEl = $state<HTMLElement | null>(null)
  let showTypes = $state(false)
  let showUrl = $state(false)
  // svelte-ignore state_referenced_locally -- menu remounts per open; initial snapshot is intended
  let urlValue = $state(node.url ?? '')
  let confirmDelete = $state(false)

  const info = $derived(noteStore.siblingInfo(node.id))
  const descendants = $derived(noteStore.descendantCount(node.id))
  const hasUrlField = $derived(node.type === 'image' || node.type === 'link')

  $effect(() => {
    const handlePointer = (e: MouseEvent) => {
      if (menuEl && !menuEl.contains(e.target as Node)) onClose()
    }
    const handleKey = (e: KeyboardEvent) => {
      if (e.key === 'Escape') { e.stopPropagation(); onClose() }
    }
    document.addEventListener('mousedown', handlePointer, true)
    document.addEventListener('keydown', handleKey, true)
    return () => {
      document.removeEventListener('mousedown', handlePointer, true)
      document.removeEventListener('keydown', handleKey, true)
    }
  })

  const openAsPage = () => { onClose(); goto(`/notes/${node.id}`) }

  const addChild = async () => {
    onClose()
    const n = await noteStore.addChild(node.id)
    onFocusChange(n.id)
  }

  const addSibling = async () => {
    onClose()
    const n = await noteStore.addAfter(node.id)
    onFocusChange(n.id)
  }

  const turnInto = (type: NoteNodeType) => {
    noteStore.update(node.id, { type })
    onClose()
  }

  const saveUrl = () => {
    // Pass the trimmed string (empty allowed) so clearing the field
    // sends url=null — `update` ignores `undefined`, which would block clears.
    noteStore.update(node.id, { url: urlValue.trim() })
    onClose()
  }

  const indent = () => { noteStore.indent(node.id); onClose(); onFocusChange(node.id) }
  const unindent = () => { noteStore.unindent(node.id); onClose(); onFocusChange(node.id) }
  const moveUp = () => { noteStore.moveUp(node.id); onClose() }
  const moveDown = () => { noteStore.moveDown(node.id); onClose() }
  const duplicate = () => { noteStore.duplicate(node.id); onClose() }

  const handleDelete = () => {
    if (descendants > 0 && !confirmDelete) {
      confirmDelete = true
      return
    }
    onClose()
    noteStore.remove(node.id).then(focusTarget => onFocusChange(focusTarget))
  }

  const types: Array<{ value: NoteNodeType; label: string }> = [
    { value: 'text', label: 'Text' },
    { value: 'heading1', label: 'Heading 1' },
    { value: 'heading2', label: 'Heading 2' },
    { value: 'bullet', label: 'Bullet' },
    { value: 'image', label: 'Image' },
    { value: 'link', label: 'Link' },
  ]
</script>

<div class="note-menu" bind:this={menuEl} role="menu">
  <button class="note-menu-item" role="menuitem" onclick={openAsPage}>Open as page</button>
  <button class="note-menu-item" role="menuitem" onclick={addChild}>Add child</button>
  <button class="note-menu-item" role="menuitem" onclick={addSibling}>Add sibling below</button>

  <button class="note-menu-item" role="menuitem" onclick={() => showTypes = !showTypes}>
    Turn into <span class="note-menu-caret">{showTypes ? '▾' : '▸'}</span>
  </button>
  {#if showTypes}
    <div class="note-menu-sub">
      {#each types as t}
        <button
          class="note-menu-item note-menu-sub-item"
          class:active={node.type === t.value}
          role="menuitem"
          onclick={() => turnInto(t.value)}
        >{t.label}</button>
      {/each}
    </div>
  {/if}

  {#if hasUrlField}
    <button class="note-menu-item" role="menuitem" onclick={() => showUrl = !showUrl}>Set URL…</button>
    {#if showUrl}
      <div class="note-menu-url">
        <!-- svelte-ignore a11y_autofocus -->
        <input
          class="note-menu-url-input"
          placeholder="https://..."
          bind:value={urlValue}
          onkeydown={(e) => { if (e.key === 'Enter') saveUrl() }}
          autofocus
        />
        <button class="note-menu-url-save" onclick={saveUrl}>Save</button>
      </div>
    {/if}
  {/if}

  <button class="note-menu-item" role="menuitem" disabled={!info || info.index < 1} onclick={indent}>
    Indent <kbd>Tab</kbd>
  </button>
  <button class="note-menu-item" role="menuitem" disabled={!info || info.isRoot} onclick={unindent}>
    Outdent <kbd>Shift+Tab</kbd>
  </button>
  <button class="note-menu-item" role="menuitem" disabled={!info || info.index < 1} onclick={moveUp}>Move up</button>
  <button class="note-menu-item" role="menuitem" disabled={!info || info.index >= info.count - 1} onclick={moveDown}>Move down</button>
  <button class="note-menu-item" role="menuitem" onclick={duplicate}>Duplicate</button>

  <div class="note-menu-sep"></div>

  <button class="note-menu-item danger" role="menuitem" onclick={handleDelete}>
    {confirmDelete ? `Delete note and ${descendants} nested?` : 'Delete'}
  </button>
</div>

<style>
  .note-menu {
    position: absolute;
    right: 4px;
    top: calc(100% - 2px);
    z-index: 50;
    min-width: 190px;
    padding: 4px;
    background: var(--color-card);
    border: 1px solid var(--color-border);
    border-radius: var(--radius);
    box-shadow: 0 4px 16px rgba(0, 0, 0, 0.12);
    display: flex;
    flex-direction: column;
  }

  .note-menu-item {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 12px;
    width: 100%;
    padding: 5px 8px;
    font-size: 12px;
    text-align: left;
    color: var(--color-text);
    background: none;
    border: none;
    border-radius: 3px;
    cursor: pointer;
    transition: background 100ms;
  }

  .note-menu-item:hover:not(:disabled) {
    background: var(--color-surface-2);
  }

  .note-menu-item:disabled {
    color: var(--color-muted-2);
    cursor: default;
  }

  .note-menu-item kbd {
    font-family: var(--font-mono);
    font-size: 10px;
    color: var(--color-muted);
  }

  .note-menu-caret {
    font-size: 10px;
    color: var(--color-muted);
  }

  .note-menu-sub {
    display: flex;
    flex-direction: column;
    border-left: 2px solid var(--color-border);
    margin-left: 10px;
  }

  .note-menu-sub-item.active {
    color: var(--color-brand-2);
    font-weight: 600;
  }

  .note-menu-url {
    display: flex;
    gap: 4px;
    padding: 4px 8px;
  }

  .note-menu-url-input {
    flex: 1;
    min-width: 0;
    font-size: 12px;
    padding: 3px 6px;
    border: 1px solid var(--color-border);
    border-radius: 3px;
    background: var(--color-surface);
    color: var(--color-text);
  }

  .note-menu-url-save {
    font-size: 11px;
    padding: 3px 8px;
    border: none;
    border-radius: 3px;
    background: var(--color-brand);
    color: #fff;
    cursor: pointer;
  }

  .note-menu-sep {
    height: 1px;
    margin: 4px 6px;
    background: var(--color-border);
  }

  .note-menu-item.danger {
    color: var(--color-danger);
  }

  .note-menu-item.danger:hover {
    background: color-mix(in srgb, var(--color-danger) 10%, transparent);
  }
</style>
