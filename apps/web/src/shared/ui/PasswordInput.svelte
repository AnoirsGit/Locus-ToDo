<script lang="ts">
  import { i18n } from '$shared/lib/i18n'
  import type { HTMLInputAttributes } from 'svelte/elements'

  type Props = {
    value: string
    id?: string
    placeholder?: string
    autocomplete?: HTMLInputAttributes['autocomplete']
    minlength?: number
    required?: boolean
  }
  let {
    value = $bindable(''),
    id,
    placeholder,
    autocomplete = 'current-password',
    minlength,
    required = false,
  }: Props = $props()

  let show = $state(false)

  // Set the input type imperatively: Svelte forbids a dynamic `type` together with
  // `bind:value`, so we omit the attribute (defaults to text binding) and toggle here.
  const inputType = (node: HTMLInputElement, type: string) => {
    node.type = type
    return { update: (t: string) => { node.type = t } }
  }
</script>

<div class="pw-wrap">
  <input
    {id}
    use:inputType={show ? 'text' : 'password'}
    bind:value
    {required}
    {minlength}
    {autocomplete}
    {placeholder}
    class="input pw-input"
  />
  <button
    type="button"
    class="pw-toggle"
    tabindex="-1"
    aria-label={show ? i18n.t('auth.hide_password') : i18n.t('auth.show_password')}
    onclick={() => (show = !show)}
  >
    {#if show}
      <svg width="16" height="16" viewBox="0 0 16 16" fill="none">
        <path d="M2 2l12 12M6.5 6.6a2 2 0 002.8 2.8M4.2 4.4C2.7 5.4 1.6 7 1.6 7s2.4 4 6.4 4c1.1 0 2-.3 2.9-.7M7 3.1c.3 0 .7-.1 1-.1 4 0 6.4 4 6.4 4s-.6 1-1.6 2"
          stroke="currentColor" stroke-width="1.3" stroke-linecap="round" stroke-linejoin="round"/>
      </svg>
    {:else}
      <svg width="16" height="16" viewBox="0 0 16 16" fill="none">
        <path d="M1.6 8S4 4 8 4s6.4 4 6.4 4-2.4 4-6.4 4-6.4-4-6.4-4z" stroke="currentColor" stroke-width="1.3" stroke-linejoin="round"/>
        <circle cx="8" cy="8" r="1.8" stroke="currentColor" stroke-width="1.3"/>
      </svg>
    {/if}
  </button>
</div>

<style>
  .pw-wrap { position: relative; }
  .pw-input { padding-right: 2.25rem; }
  .pw-toggle {
    position: absolute;
    right: 0.5rem;
    top: 50%;
    transform: translateY(-50%);
    display: inline-flex;
    align-items: center;
    justify-content: center;
    padding: 4px;
    border-radius: 5px;
    color: var(--color-muted);
    cursor: pointer;
  }
  .pw-toggle:hover { color: var(--color-text); }
</style>
