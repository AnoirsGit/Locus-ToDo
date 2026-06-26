<script lang="ts">
  import Skeleton from './Skeleton.svelte'

  // Placeholder snapshot cards shown while the stats page loads.
  const levels = ['level-day', 'level-week', 'level-month', 'level-year']
</script>

<section class="section" aria-hidden="true">
  <div class="snap-grid">
    {#each levels as level (level)}
      <div class="snap-card {level}">
        <Skeleton width="40%" height="11px" />
        <div class="mt-3"><Skeleton width="55%" height="22px" /></div>
        <div class="mt-3"><Skeleton width="100%" height="6px" rounded="9999px" /></div>
        <div class="mt-2"><Skeleton width="28%" height="10px" /></div>
      </div>
    {/each}
  </div>
</section>
