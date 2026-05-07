<script lang="ts">
  import type { Snippet } from 'svelte'
  type Props = { children: Snippet }
  const { children }: Props = $props()
</script>

<div class="docs-shell">
  {@render children()}
</div>

<style>
  .docs-shell {
    min-height: 100vh;
    background: var(--color-background);
  }
</style>
