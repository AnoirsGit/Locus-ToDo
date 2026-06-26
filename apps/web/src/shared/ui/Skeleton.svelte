<script lang="ts">
  // Generic shimmer placeholder block. Sizes via props; colors follow the theme.
  type Props = { width?: string; height?: string; rounded?: string; class?: string }
  const { width = '100%', height = '1rem', rounded = '0.375rem', class: className = '' }: Props = $props()
</script>

<div
  class="animate-pulse {className}"
  style="width:{width}; height:{height}; border-radius:{rounded}; background: var(--color-surface-2)"
  aria-hidden="true"
></div>
