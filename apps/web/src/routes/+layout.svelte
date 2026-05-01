<script lang="ts">
  import '../app.css'
  import type { Snippet } from 'svelte'

  type Props = { children: Snippet }
  const { children }: Props = $props()
</script>

<main>
  {@render children()}
</main>

<style>
  main {
    display: flex;
    min-height: 100vh;
  }
</style>
