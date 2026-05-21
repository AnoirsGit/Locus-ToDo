<script lang="ts">
  import type { NoteNode } from '$entities/note'
  import { noteStore } from '$entities/note'

  type Props = {
    node: NoteNode
    depth: number
    focusId: string | null
    onFocusChange: (id: string | null) => void
  }
  const { node, depth, focusId, onFocusChange }: Props = $props()

  let inputEl = $state<HTMLElement | null>(null)
  let urlInputEl = $state<HTMLInputElement | null>(null)
  let showUrlInput = $state(false)

  // Auto-focus when this node is the target
  $effect(() => {
    if (focusId === node.id && inputEl) {
      inputEl.focus()
      // Move cursor to end
      if (inputEl instanceof HTMLInputElement || inputEl instanceof HTMLTextAreaElement) {
        const len = inputEl.value.length
        inputEl.setSelectionRange(len, len)
      }
    }
  })

  const handleKeydown = (e: KeyboardEvent) => {
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

  const hasChildren = $derived(node.children.length > 0)
  const indentPx = $derived(depth * 24)
</script>

<div class="note-row" style:padding-left="{indentPx}px">

  <!-- Collapse toggle / bullet -->
  <button
    class="note-bullet"
    class:has-children={hasChildren}
    class:collapsed={node.collapsed}
    onclick={() => hasChildren && noteStore.toggleCollapse(node.id)}
    tabindex="-1"
    aria-label={hasChildren ? (node.collapsed ? 'Expand' : 'Collapse') : 'Bullet'}
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
          onfocus={() => onFocusChange(node.id)}
          bind:this={inputEl}
        />
        <button
          class="note-url-toggle"
          onclick={() => showUrlInput = !showUrlInput}
          tabindex="-1"
        >
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
          onfocus={() => onFocusChange(node.id)}
          bind:this={inputEl}
        />
        {#if node.url}
          <a href={node.url} target="_blank" rel="noopener" class="note-link-href">↗</a>
        {/if}
        <button
          class="note-url-toggle"
          onclick={() => showUrlInput = !showUrlInput}
          tabindex="-1"
        >
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
        onfocus={() => onFocusChange(node.id)}
        bind:this={inputEl}
      />
    {/if}

    <!-- Type selector (shown on focus) -->
    {#if focusId === node.id}
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
</div>

<!-- Children -->
{#if !node.collapsed && node.children.length > 0}
  {#each node.children as child (child.id)}
    <svelte:self
      node={child}
      depth={depth + 1}
      {focusId}
      {onFocusChange}
    />
  {/each}
{/if}
