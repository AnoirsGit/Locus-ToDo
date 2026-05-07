/**
 * Svelte action: drag-to-scroll a horizontally scrollable container.
 * Works with mouse on desktop; doesn't interfere with native touch scroll on mobile.
 * Ignores drags that start on interactive elements (button, a, input).
 */
export function dragScroll(node: HTMLElement) {
  let active = false
  let startX = 0
  let scrollLeft = 0

  const onDown = (e: PointerEvent) => {
    if (e.pointerType === 'touch') return // let browser handle touch natively
    if ((e.target as Element).closest('button, a, input, textarea, select')) return

    active = true
    startX = e.clientX
    scrollLeft = node.scrollLeft
    node.setPointerCapture(e.pointerId)
    node.style.cursor = 'grabbing'
    node.style.userSelect = 'none'
  }

  const onMove = (e: PointerEvent) => {
    if (!active) return
    node.scrollLeft = scrollLeft - (e.clientX - startX)
  }

  const onUp = () => {
    if (!active) return
    active = false
    node.style.cursor = ''
    node.style.userSelect = ''
  }

  node.addEventListener('pointerdown', onDown)
  node.addEventListener('pointermove', onMove)
  node.addEventListener('pointerup', onUp)
  node.addEventListener('pointercancel', onUp)

  return {
    destroy() {
      node.removeEventListener('pointerdown', onDown)
      node.removeEventListener('pointermove', onMove)
      node.removeEventListener('pointerup', onUp)
      node.removeEventListener('pointercancel', onUp)
    },
  }
}
