<script lang="ts">
  import Skeleton from './Skeleton.svelte'

  // Placeholder task cards shown while a task list loads.
  type Props = { count?: number }
  const { count = 5 }: Props = $props()

  const widths = ['68%', '54%', '61%', '47%', '72%']
</script>

<div class="flex flex-col gap-2" aria-hidden="true">
  {#each Array(count) as _, i (i)}
    <div
      class="flex items-center gap-3 p-3 rounded-lg"
      style="background: var(--color-card); border: 1px solid var(--color-border)"
    >
      <Skeleton width="18px" height="18px" rounded="50%" />
      <div class="flex-1 flex flex-col gap-2">
        <Skeleton width={widths[i % widths.length]} height="13px" />
        <Skeleton width="30%" height="9px" />
      </div>
    </div>
  {/each}
</div>
