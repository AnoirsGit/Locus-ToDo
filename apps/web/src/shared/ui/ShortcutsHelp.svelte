<script lang="ts">
  import { i18n } from '$shared/lib/i18n'
  import { trapFocus } from '$shared/lib/focusTrap'

  type Props = { onClose: () => void }
  const { onClose }: Props = $props()

  const navRows: Array<{ keys: string; labelKey: string }> = [
    { keys: 'g t', labelKey: 'nav.today' },
    { keys: 'g w', labelKey: 'nav.week' },
    { keys: 'g m', labelKey: 'nav.month' },
    { keys: 'g y', labelKey: 'nav.year' },
    { keys: 'g b', labelKey: 'nav.backlog' },
    { keys: 'g a', labelKey: 'nav.archive' },
    { keys: 'g s', labelKey: 'nav.stats' },
    { keys: 'g n', labelKey: 'nav.notes' },
  ]
</script>

<div class="modal-backdrop" role="dialog" aria-modal="true">
  <button class="absolute inset-0 w-full h-full cursor-default" aria-label={i18n.t('action.close')} tabindex="-1" onclick={onClose}></button>

  <div class="modal" tabindex="-1" use:trapFocus style="max-width: 22rem">
    <div class="tmodal-header">
      <span class="modal-eyebrow">{i18n.t('shortcuts.title')}</span>
      <button class="btn-icon ml-auto shrink-0" onclick={onClose} aria-label={i18n.t('action.close')}>
        <svg class="w-4 h-4" viewBox="0 0 16 16" fill="none">
          <path d="M4 4l8 8M12 4l-8 8" stroke="currentColor" stroke-width="1.5" stroke-linecap="round"/>
        </svg>
      </button>
    </div>

    <div class="flex flex-col gap-1.5 p-1">
      <div class="sc-row">
        <span class="sc-label">{i18n.t('shortcuts.create')}</span>
        <span class="sc-keys"><kbd>c</kbd></span>
      </div>

      <div class="sc-section">{i18n.t('shortcuts.go_prefix')}</div>
      {#each navRows as row (row.keys)}
        <div class="sc-row">
          <span class="sc-label">{i18n.t(row.labelKey)}</span>
          <span class="sc-keys">
            {#each row.keys.split(' ') as k (k)}<kbd>{k}</kbd>{/each}
          </span>
        </div>
      {/each}

      <div class="sc-row">
        <span class="sc-label">{i18n.t('shortcuts.help')}</span>
        <span class="sc-keys"><kbd>?</kbd></span>
      </div>
    </div>
  </div>
</div>

<style>
  .sc-row { display: flex; align-items: center; justify-content: space-between; padding: 0.3rem 0.5rem; }
  .sc-label { font-size: 13px; color: var(--color-text-2); }
  .sc-section { font-size: 10.5px; text-transform: uppercase; letter-spacing: 0.08em; color: var(--color-muted); padding: 0.5rem 0.5rem 0.1rem; }
  .sc-keys { display: inline-flex; gap: 0.25rem; }
  kbd {
    font-family: var(--font-mono, monospace);
    font-size: 11px;
    line-height: 1;
    padding: 3px 6px;
    border: 1px solid var(--color-border-2);
    border-bottom-width: 2px;
    border-radius: 5px;
    background: var(--color-surface);
    color: var(--color-text);
  }
</style>
