<script lang="ts">
  import type { NoteNode } from '$entities/note'
  import { noteStore } from '$entities/note'
  import NoteRow from './NoteRow.svelte'

  let focusId = $state<string | null>(null)

  $effect(() => { noteStore.load() })

  const handleFocusChange = (id: string | null) => {
    focusId = id
  }

  const handleAddRoot = async () => {
    const node = await noteStore.addRoot()
    focusId = node.id
  }
</script>

<div class="note-tree">
  {#each noteStore.nodes as node (node.id)}
    <NoteRow
      {node}
      depth={0}
      {focusId}
      onFocusChange={handleFocusChange}
    />
  {/each}

  <button class="note-add-root" onclick={handleAddRoot}>
    <svg width="12" height="12" viewBox="0 0 12 12" fill="none">
      <path d="M6 1v10M1 6h10" stroke="currentColor" stroke-width="1.5" stroke-linecap="round"/>
    </svg>
    Add note
  </button>
</div>
