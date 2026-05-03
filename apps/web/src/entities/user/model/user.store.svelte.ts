import type { User } from './user.types'

type State = {
  user: User | null
  loading: boolean
}

const state = $state<State>({ user: null, loading: false })

export const userStore = {
  get user() { return state.user },
  get loading() { return state.loading },
  get isAuthed() { return state.user !== null },

  set: (user: User) => { state.user = user },
  patch: (p: Partial<User>) => { if (state.user) state.user = { ...state.user, ...p } },
  clear: () => { state.user = null },
  setLoading: (v: boolean) => { state.loading = v },
}
