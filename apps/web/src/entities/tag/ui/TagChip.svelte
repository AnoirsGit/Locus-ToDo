<script lang="ts">
  import type { Tag } from '../model/tag.types'

  type Props = {
    tag: Tag
    onRemove?: () => void
  }
  const { tag, onRemove }: Props = $props()

  const bg = $derived(tag.color ?? 'var(--color-surface)')
  const isCustomColor = $derived(!!tag.color)
</script>

<span
  class="tag-chip"
  style:background={bg}
  style:color={isCustomColor ? '#fff' : 'var(--color-text)'}
>
  {tag.name}
  {#if onRemove}
    <button class="tag-chip-remove" onclick={onRemove} aria-label="Remove tag" tabindex="-1">
      <svg viewBox="0 0 8 8" fill="none" width="8" height="8">
        <path d="M1 1l6 6M7 1L1 7" stroke="currentColor" stroke-width="1.3" stroke-linecap="round"/>
      </svg>
    </button>
  {/if}
</span>

<style>
  .tag-chip {
    display: inline-flex;
    align-items: center;
    gap: 4px;
    padding: 2px 7px;
    border-radius: 20px;
    font-size: 11px;
    font-weight: 500;
    line-height: 1.4;
    white-space: nowrap;
    border: 1px solid rgba(0,0,0,0.08);
  }

  .tag-chip-remove {
    display: flex;
    align-items: center;
    padding: 0;
    background: none;
    border: none;
    cursor: pointer;
    opacity: 0.7;
    color: inherit;
  }

  .tag-chip-remove:hover {
    opacity: 1;
  }
</style>
