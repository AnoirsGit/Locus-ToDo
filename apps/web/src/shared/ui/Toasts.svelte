<script lang="ts">
  import { toastStore } from '$shared/lib/toast.svelte'
</script>

{#if toastStore.items.length > 0}
  <div class="toast-container">
    {#each toastStore.items as toast (toast.id)}
      <div class="toast toast--{toast.type}">
        <span class="toast-msg">{toast.message}</span>
        <button class="toast-close" onclick={() => toastStore.remove(toast.id)}>
          <svg width="12" height="12" viewBox="0 0 12 12" fill="none">
            <path d="M1 1l10 10M11 1L1 11" stroke="currentColor" stroke-width="1.5" stroke-linecap="round"/>
          </svg>
        </button>
      </div>
    {/each}
  </div>
{/if}
