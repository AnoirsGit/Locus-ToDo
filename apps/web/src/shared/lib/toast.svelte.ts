export type ToastType = 'error' | 'success' | 'info'
export type ToastAction = { label: string; run: () => void }
export type Toast = { id: number; message: string; type: ToastType; action?: ToastAction }

/** Lifetime of an Undo toast. */
export const UNDO_TOAST_MS = 5000

let nextId = 0

const state = $state<{ items: Toast[] }>({ items: [] })

/** `duration <= 0` makes the toast sticky: it stays until dismissed or its action runs. */
const add = (message: string, type: ToastType, duration = 4000, action?: ToastAction): number => {
  const id = ++nextId
  state.items = [...state.items, { id, message, type, action }]
  if (duration > 0) setTimeout(() => remove(id), duration)
  return id
}

const remove = (id: number) => {
  state.items = state.items.filter(t => t.id !== id)
}

export const toastStore = {
  get items() { return state.items },
  error:   (msg: string) => add(msg, 'error'),
  success: (msg: string) => add(msg, 'success'),
  info:    (msg: string) => add(msg, 'info'),
  /** Toast with an action button (e.g. Undo). Returns the toast id. */
  withAction: (msg: string, action: ToastAction, type: ToastType = 'info', duration = UNDO_TOAST_MS) =>
    add(msg, type, duration, action),
  has: (id: number) => state.items.some(t => t.id === id),
  remove,
}
