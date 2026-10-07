<script lang="ts">
  import '../app/app.css'
  import type { Snippet } from 'svelte'
  import { onMount } from 'svelte'
  import { i18n } from '$shared/lib/i18n'

  type Props = { children: Snippet }
  const { children }: Props = $props()

  // Apply the saved language on every route: the (auth) pages have no layout of
  // their own, so a fresh /login load always rendered the default 'ru'.
  onMount(() => i18n.restore())
</script>

<svelte:head><title>Locus</title></svelte:head>

{@render children()}
