<script lang="ts">
  import { tagStore } from '$entities/tag'
  import { TagChip } from '$entities/tag'
  import { onMount } from 'svelte'

  onMount(() => tagStore.load())

  const PRESET_COLORS = [
    '#ef4444', '#f97316', '#eab308', '#22c55e',
    '#06b6d4', '#3b82f6', '#8b5cf6', '#ec4899',
  ]

  let newName = $state('')
  let newColor = $state<string | null>(null)
  let creating = $state(false)

  type EditState = { id: string; name: string; color: string | null } | null
  let editing = $state<EditState>(null)

  const handleCreate = async () => {
    const name = newName.trim()
    if (!name || creating) return
    creating = true
    try {
      await tagStore.create(name, newColor)
      newName = ''
      newColor = null
    } finally {
      creating = false
    }
  }

  const startEdit = (id: string, name: string, color: string | null) => {
    editing = { id, name, color }
  }

  const saveEdit = async () => {
    if (!editing) return
    await tagStore.update(editing.id, { name: editing.name.trim(), color: editing.color })
    editing = null
  }
</script>

<div class="tags-settings">
  <!-- Existing tags -->
  <div class="tags-list">
    {#each tagStore.tags as tag (tag.id)}
      {#if editing?.id === tag.id}
        <div class="tag-edit-row">
          <input
            class="tag-edit-input"
            bind:value={editing.name}
            onkeydown={(e) => { if (e.key === 'Enter') saveEdit(); if (e.key === 'Escape') editing = null }}
          />
          <div class="tag-edit-colors">
            <button
              class="tag-color-dot"
              class:selected={editing.color === null}
              style:background="var(--color-muted)"
              onclick={() => { editing!.color = null }}
              title="No color"
            ></button>
            {#each PRESET_COLORS as c}
              <button
                class="tag-color-dot"
                class:selected={editing.color === c}
                style:background={c}
                onclick={() => { editing!.color = c }}
                title={c}
              ></button>
            {/each}
          </div>
          <button class="btn-sm primary" onclick={saveEdit}>Save</button>
          <button class="btn-sm ghost" onclick={() => editing = null}>Cancel</button>
        </div>
      {:else}
        <div class="tag-row">
          <TagChip {tag} />
          <div class="tag-row-actions">
            <button class="btn-icon" onclick={() => startEdit(tag.id, tag.name, tag.color)} title="Edit">
              <svg viewBox="0 0 12 12" fill="none" width="12" height="12">
                <path d="M7.5 1.5L10.5 4.5M1 9.5L1.5 11L3.5 10.5L10.5 3.5L8.5 1.5L1 9.5Z"
                  stroke="currentColor" stroke-width="1.2" stroke-linecap="round" stroke-linejoin="round"/>
              </svg>
            </button>
            <button class="btn-icon text-danger" onclick={() => tagStore.delete(tag.id)} title="Delete">
              <svg viewBox="0 0 12 12" fill="none" width="12" height="12">
                <path d="M2 2l8 8M10 2l-8 8" stroke="currentColor" stroke-width="1.4" stroke-linecap="round"/>
              </svg>
            </button>
          </div>
        </div>
      {/if}
    {/each}

    {#if tagStore.tags.length === 0 && tagStore.loaded}
      <p class="tags-empty">No tags yet. Create one below.</p>
    {/if}
  </div>

  <!-- Create new tag -->
  <div class="tag-create-form">
    <div class="tag-create-row">
      <input
        class="tag-create-input"
        placeholder="Tag name…"
        bind:value={newName}
        onkeydown={(e) => { if (e.key === 'Enter') handleCreate() }}
      />
      <button class="btn-sm primary" onclick={handleCreate} disabled={creating || !newName.trim()}>
        Add tag
      </button>
    </div>
    <div class="tag-create-colors">
      <span class="tag-create-color-label">Color:</span>
      <button
        class="tag-color-dot"
        class:selected={newColor === null}
        style:background="var(--color-muted)"
        onclick={() => newColor = null}
        title="No color"
      ></button>
      {#each PRESET_COLORS as c}
        <button
          class="tag-color-dot"
          class:selected={newColor === c}
          style:background={c}
          onclick={() => newColor = c}
          title={c}
        ></button>
      {/each}
    </div>
    {#if newName || newColor}
      <div class="tag-create-preview">
        <span class="text-[11px] text-muted">Preview:</span>
        <span
          class="tag-chip"
          style:background={newColor ?? 'var(--color-surface)'}
          style:color={newColor ? '#fff' : 'var(--color-text)'}
        >{newName || 'Tag name'}</span>
      </div>
    {/if}
  </div>
</div>

<style>
  .tags-settings {
    display: flex;
    flex-direction: column;
    gap: 16px;
  }

  .tags-list {
    display: flex;
    flex-direction: column;
    gap: 4px;
  }

  .tag-row {
    display: flex;
    align-items: center;
    justify-content: space-between;
    padding: 6px 8px;
    border-radius: var(--radius);
    border: 1px solid var(--color-border);
    background: var(--color-card);
  }

  .tag-row-actions {
    display: flex;
    gap: 2px;
  }

  .tag-edit-row {
    display: flex;
    flex-wrap: wrap;
    align-items: center;
    gap: 8px;
    padding: 8px;
    border-radius: var(--radius);
    border: 1px solid var(--color-accent);
    background: var(--color-card);
  }

  .tag-edit-input {
    flex: 1;
    min-width: 120px;
    padding: 4px 8px;
    border: 1px solid var(--color-border);
    border-radius: 4px;
    background: var(--color-surface);
    color: var(--color-text);
    font-size: 13px;
  }

  .tag-edit-colors {
    display: flex;
    gap: 4px;
    align-items: center;
  }

  .tag-color-dot {
    width: 18px;
    height: 18px;
    border-radius: 50%;
    border: 2px solid transparent;
    cursor: pointer;
    transition: border-color 0.1s, transform 0.1s;
  }

  .tag-color-dot:hover {
    transform: scale(1.15);
  }

  .tag-color-dot.selected {
    border-color: var(--color-text);
  }

  .tags-empty {
    font-size: 13px;
    color: var(--color-muted);
    padding: 8px;
  }

  .tag-create-form {
    display: flex;
    flex-direction: column;
    gap: 8px;
    padding: 12px;
    border: 1px dashed var(--color-border);
    border-radius: var(--radius);
  }

  .tag-create-row {
    display: flex;
    gap: 8px;
  }

  .tag-create-input {
    flex: 1;
    padding: 6px 10px;
    border: 1px solid var(--color-border);
    border-radius: var(--radius);
    background: var(--color-surface);
    color: var(--color-text);
    font-size: 13px;
  }

  .tag-create-colors {
    display: flex;
    align-items: center;
    gap: 6px;
  }

  .tag-create-color-label {
    font-size: 12px;
    color: var(--color-muted);
  }

  .tag-create-preview {
    display: flex;
    align-items: center;
    gap: 8px;
  }

  .btn-sm {
    padding: 5px 12px;
    border-radius: var(--radius);
    font-size: 12px;
    font-weight: 500;
    cursor: pointer;
    border: none;
  }

  .btn-sm.primary {
    background: var(--color-accent);
    color: #fff;
  }

  .btn-sm.primary:disabled {
    opacity: 0.4;
    cursor: default;
  }

  .btn-sm.ghost {
    background: transparent;
    color: var(--color-text);
    border: 1px solid var(--color-border);
  }

  .text-danger { color: var(--color-error, #ef4444); }
</style>
