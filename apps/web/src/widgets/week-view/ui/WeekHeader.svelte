<script lang="ts">
  let { weekOffset = $bindable(), weekLabel } = $props<{
    weekOffset: number;
    weekLabel: string;
  }>();
</script>

<div class="page-header">
  <div class="page-header-left">
    <div class="page-eyebrow">Горизонт · неделя</div>
    <h1 class="page-title"><em>Неделя.</em></h1>
  </div>
  <div class="page-actions">
    <button class="btn-icon" onclick={() => weekOffset -= 1} aria-label="Предыдущая неделя">
      <svg class="w-4 h-4" viewBox="0 0 16 16" fill="none">
        <path d="M10 12L6 8l4-4" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
      </svg>
    </button>
    <span class="font-medium text-sm min-w-44 text-center text-text">{weekLabel}</span>
    <button class="btn-icon" onclick={() => weekOffset += 1} aria-label="Следующая неделя">
      <svg class="w-4 h-4" viewBox="0 0 16 16" fill="none">
        <path d="M6 4l4 4-4 4" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
      </svg>
    </button>
  </div>
</div>
