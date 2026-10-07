<script lang="ts">
  import { i18n } from '$shared/lib/i18n'

  let { weekOffset = $bindable(), weekLabel } = $props<{
    weekOffset: number;
    weekLabel: string;
  }>();
</script>

<div class="page-header">
  <div class="page-header-left">
    <div class="page-eyebrow">{i18n.t('view.week_eyebrow')}</div>
    <h1 class="page-title"><em>{i18n.t('view.week')}</em></h1>
  </div>
  <div class="page-actions">
    <button class="btn-icon" onclick={() => weekOffset -= 1} aria-label={i18n.t('view.prev_week')}>
      <svg class="w-4 h-4" viewBox="0 0 16 16" fill="none">
        <path d="M10 12L6 8l4-4" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
      </svg>
    </button>
    <span class="font-medium text-sm min-w-44 text-center text-text">{weekLabel}</span>
    <button class="btn-icon" onclick={() => weekOffset += 1} aria-label={i18n.t('view.next_week')}>
      <svg class="w-4 h-4" viewBox="0 0 16 16" fill="none">
        <path d="M6 4l4 4-4 4" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
      </svg>
    </button>
  </div>
</div>
