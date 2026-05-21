<script lang="ts">
  import { tagStore } from '../model/tag.store.svelte'
  import TagChip from './TagChip.svelte'
  import type { Tag } from '../model/tag.types'

  type Props = {
    selectedIds: string[]
    onChange: (ids: string[]) => void
  }
  const { selectedIds, onChange }: Props = $props()

  let open = $state(false)
  let newName = $state('')
  let creating = $state(false)

  $effect(() => { tagStore.load() })

  const selectedTags = $derived(
    tagStore.tags.filter(t => selectedIds.includes(t.id))
  )

  const toggle = (id: string) => {
    if (selectedIds.includes(id)) {
      onChange(selectedIds.filter(i => i !== id))
    } else {
      onChange([...selectedIds, id])
    }
  }

  const handleCreate = async () => {
    const name = newName.trim()
    if (!name) return
    creating = true
    try {
      const tag = await tagStore.create(name)
      onChange([...selectedIds, tag.id])
      newName = ''
    } finally {
      creating = false
    }
  }
</script>

<div class="tag-picker">
  <div class="tag-picker-chips">
    {#each selectedTags as tag (tag.id)}
      <TagChip {tag} onRemove={() => toggle(tag.id)} />
    {/each}
    <button class="tag-picker-add-btn" onclick={() => open = !open} type="button" aria-label="Add tag">
      <svg viewBox="0 0 10 10" fill="none" width="10" height="10">
        <path d="M5 1v8M1 5h8" stroke="currentColor" stroke-width="1.4" stroke-linecap="round"/>
      </svg>
    </button>
  </div>

  {#if open}
    <div class="tag-picker-dropdown">
      {#each tagStore.tags as tag (tag.id)}
        <button
          type="button"
          class="tag-picker-option"
          class:selected={selectedIds.includes(tag.id)}
          onclick={() => toggle(tag.id)}
        >
          <span class="tag-picker-dot" style:background={tag.color ?? 'var(--color-muted)'}></span>
          {tag.name}
          {#if selectedIds.includes(tag.id)}
            <svg class="tag-picker-check" viewBox="0 0 10 10" fill="none" width="10" height="10">
              <path d="M1.5 5l2.5 2.5L8.5 2" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"/>
            </svg>
          {/if}
        </button>
      {/each}

      <div class="tag-picker-create">
        <input
          class="tag-picker-input"
          placeholder="New tag…"
          bind:value={newName}
          onkeydown={(e) => { if (e.key === 'Enter') { e.preventDefault(); handleCreate() } }}
        />
        <button type="button" class="tag-picker-create-btn" onclick={handleCreate} disabled={creating || !newName.trim()}>
          Add
        </button>
      </div>
    </div>
  {/if}
</div>

<style>
  .tag-picker {
    position: relative;
  }

  .tag-picker-chips {
    display: flex;
    flex-wrap: wrap;
    align-items: center;
    gap: 4px;
  }

  .tag-picker-add-btn {
    display: flex;
    align-items: center;
    justify-content: center;
    width: 22px;
    height: 22px;
    border-radius: 50%;
    border: 1px dashed var(--color-border);
    background: none;
    color: var(--color-muted);
    cursor: pointer;
  }

  .tag-picker-add-btn:hover {
    color: var(--color-text);
    border-color: var(--color-text);
  }

  .tag-picker-dropdown {
    position: absolute;
    top: calc(100% + 6px);
    left: 0;
    z-index: 50;
    min-width: 180px;
    background: var(--color-card);
    border: 1px solid var(--color-border);
    border-radius: var(--radius);
    box-shadow: 0 4px 12px rgba(0,0,0,0.1);
    padding: 4px;
  }

  .tag-picker-option {
    display: flex;
    align-items: center;
    gap: 7px;
    width: 100%;
    padding: 6px 8px;
    border: none;
    background: none;
    border-radius: 4px;
    cursor: pointer;
    font-size: 13px;
    color: var(--color-text);
    text-align: left;
  }

  .tag-picker-option:hover {
    background: var(--color-surface);
  }

  .tag-picker-option.selected {
    font-weight: 500;
  }

  .tag-picker-dot {
    width: 8px;
    height: 8px;
    border-radius: 50%;
    flex-shrink: 0;
  }

  .tag-picker-check {
    margin-left: auto;
    color: var(--color-accent);
  }

  .tag-picker-create {
    display: flex;
    gap: 4px;
    padding: 4px 4px 2px;
    border-top: 1px solid var(--color-border);
    margin-top: 2px;
  }

  .tag-picker-input {
    flex: 1;
    min-width: 0;
    padding: 4px 6px;
    border: 1px solid var(--color-border);
    border-radius: 4px;
    background: var(--color-surface);
    color: var(--color-text);
    font-size: 12px;
  }

  .tag-picker-create-btn {
    padding: 4px 8px;
    border: none;
    border-radius: 4px;
    background: var(--color-accent);
    color: #fff;
    font-size: 12px;
    cursor: pointer;
  }

  .tag-picker-create-btn:disabled {
    opacity: 0.4;
    cursor: default;
  }
</style>
