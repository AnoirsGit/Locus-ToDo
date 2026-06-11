<script lang="ts">
  import { tagStore } from '../model/tag.store.svelte'
</script>

{#if tagStore.tags.length > 0}
  <div class="tag-filter-bar">
    {#each tagStore.tags as tag (tag.id)}
      {@const active = tagStore.noteFilterTagIds.has(tag.id)}
      <button
        class="tag-filter-pill"
        class:active
        style:--pill-color={tag.color ?? 'var(--color-muted)'}
        onclick={() => tagStore.toggleNoteFilterTag(tag.id)}
      >
        <span class="tag-filter-dot"></span>
        {tag.name}
      </button>
    {/each}

    {#if tagStore.isFilteringNotes}
      <button class="tag-filter-clear" onclick={() => tagStore.clearNoteFilter()}>
        Clear filter
      </button>
    {/if}
  </div>
{/if}

<style>
  .tag-filter-bar {
    display: flex;
    align-items: center;
    gap: 6px;
    flex-wrap: wrap;
    padding: 0 0 8px;
  }

  .tag-filter-pill {
    display: inline-flex;
    align-items: center;
    gap: 5px;
    padding: 3px 10px 3px 8px;
    border-radius: 20px;
    font-size: 11.5px;
    font-weight: 500;
    background: var(--color-surface);
    border: 1px solid var(--color-border);
    color: var(--color-muted);
    cursor: pointer;
    transition: background 100ms, border-color 100ms, color 100ms;
  }

  .tag-filter-pill:hover {
    border-color: var(--pill-color);
    color: var(--color-text);
  }

  .tag-filter-pill.active {
    background: color-mix(in srgb, var(--pill-color) 15%, transparent);
    border-color: var(--pill-color);
    color: var(--color-text);
  }

  .tag-filter-dot {
    width: 6px;
    height: 6px;
    border-radius: 50%;
    background: var(--pill-color);
    flex-shrink: 0;
  }

  .tag-filter-clear {
    font-size: 11px;
    color: var(--color-muted);
    background: none;
    border: none;
    cursor: pointer;
    padding: 2px 6px;
    border-radius: 4px;
    transition: color 100ms;
    margin-left: 2px;
  }

  .tag-filter-clear:hover {
    color: var(--color-text);
  }
</style>
