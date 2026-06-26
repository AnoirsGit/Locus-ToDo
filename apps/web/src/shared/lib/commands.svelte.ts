// Lightweight command bus so global shortcuts can trigger view-local actions
// (e.g. the keyboard "create task" shortcut opens whichever view's create modal).
let createTick = $state(0)

export const commands = {
  /** Increments whenever a "create task" was requested via a global shortcut. */
  get createTick() {
    return createTick
  },
  requestCreate() {
    createTick++
  },
}
