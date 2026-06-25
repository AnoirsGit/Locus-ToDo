/**
 * Svelte action: trap keyboard focus inside a modal/dialog node.
 * - On mount: focuses the first focusable element, unless the node already
 *   contains focus (respects a child's autofocus).
 * - Tab / Shift+Tab wrap around inside the node instead of escaping it.
 * - On destroy: restores focus to whatever was focused before the node opened.
 */
export function trapFocus(node: HTMLElement) {
  const previouslyFocused = document.activeElement as HTMLElement | null

  const SELECTOR =
    'a[href], button:not([disabled]), input:not([disabled]), select:not([disabled]), textarea:not([disabled]), [tabindex]:not([tabindex="-1"])'

  const focusables = () =>
    Array.from(node.querySelectorAll<HTMLElement>(SELECTOR)).filter(
      (el) => el.offsetParent !== null || el === document.activeElement,
    )

  // Defer so child autofocus / initial render settles first.
  queueMicrotask(() => {
    if (node.contains(document.activeElement)) return
    const els = focusables()
    ;(els[0] ?? node).focus()
  })

  const onKeydown = (e: KeyboardEvent) => {
    if (e.key !== 'Tab') return
    const els = focusables()
    if (els.length === 0) {
      e.preventDefault()
      node.focus()
      return
    }
    const first = els[0]
    const last = els[els.length - 1]
    const active = document.activeElement as HTMLElement

    if (e.shiftKey && (active === first || !node.contains(active))) {
      e.preventDefault()
      last.focus()
    } else if (!e.shiftKey && (active === last || !node.contains(active))) {
      e.preventDefault()
      first.focus()
    }
  }

  node.addEventListener('keydown', onKeydown)

  return {
    destroy() {
      node.removeEventListener('keydown', onKeydown)
      previouslyFocused?.focus?.()
    },
  }
}
