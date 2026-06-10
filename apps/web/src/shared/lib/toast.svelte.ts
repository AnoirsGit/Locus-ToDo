export type ToastType = 'error' | 'success' | 'info'
export type Toast = { id: number; message: string; type: ToastType }

let nextId = 0

const state = $state<{ items: Toast[] }>({ items: [] })

const add = (message: string, type: ToastType, duration = 4000) => {
  const id = ++nextId
  state.items = [...state.items, { id, message, type }]
  setTimeout(() => remove(id), duration)
}

const remove = (id: number) => {
  state.items = state.items.filter(t => t.id !== id)
}

export const toastStore = {
  get items() { return state.items },
  error:   (msg: string) => add(msg, 'error'),
  success: (msg: string) => add(msg, 'success'),
  info:    (msg: string) => add(msg, 'info'),
  remove,
}
