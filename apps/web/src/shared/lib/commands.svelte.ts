// Lightweight command bus so global shortcuts can trigger view-local actions
// (e.g. the keyboard "create task" shortcut opens whichever view's create modal).
// Views register a handler while mounted; a press with no registered handler is
// a no-op and never leaks into a view mounted later.
type Handler = () => void

const createHandlers: Handler[] = []

export const commands = {
  /** Register the mounted view's "create" action. Returns the unregister function. */
  onCreate(handler: Handler): () => void {
    createHandlers.push(handler)
    return () => {
      const i = createHandlers.lastIndexOf(handler)
      if (i !== -1) createHandlers.splice(i, 1)
    }
  },
  /** Run the most recently registered "create" action. Returns false when no view handles it. */
  requestCreate(): boolean {
    const handler = createHandlers.at(-1)
    handler?.()
    return handler !== undefined
  },
}
