<script lang="ts">
  import '../app/app.css'
  import type { Snippet } from 'svelte'

  type Props = { children: Snippet }
  const { children }: Props = $props()
</script>

<svelte:head><title>Locus</title></svelte:head>

{@render children()}
