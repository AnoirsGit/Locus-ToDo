# arch/frontend.md

> Load when: web app (apps/web) — components, stores, routing, UI.

## Stack

| Tool             | Version  | Role                              |
|------------------|----------|-----------------------------------|
| SvelteKit        | 2.x      | Framework + file-based routing    |
| Svelte           | 5.x      | UI + runes reactivity             |
| Tailwind CSS     | 4.x      | Styling (Vite plugin, no config file) |
| shadcn-svelte    | latest   | UI component primitives           |
| bits-ui          | 2.x      | Headless primitives (shadcn dep)  |
| lucide-svelte    | 1.x      | Icons                             |
| clsx + tw-merge  | —        | `cn()` utility                    |

---

## Architecture: Feature-Sliced Design (FSD)

```
apps/web/src/
├── app.html                        # SvelteKit entry HTML
├── app.css                         # @import "tailwindcss" + @theme tokens
│
├── routes/                         # = FSD "pages" layer (SvelteKit routing)
│   ├── +layout.svelte              # Root layout — imports app.css
│   ├── +page.svelte                # Redirects → /today
│   ├── (app)/                      # Authenticated shell
│   │   ├── +layout.svelte          # Sidebar + main wrapper
│   │   ├── today/+page.svelte      # Default view: tasks for today (targetDate = today)
│   │   ├── week/+page.svelte       # Uses WeekView widget
│   │   ├── month/+page.svelte
│   │   ├── year/+page.svelte
│   │   ├── backlog/+page.svelte
│   │   ├── archive/+page.svelte
│   │   └── settings/+page.svelte
│   └── (auth)/
│       ├── login/+page.svelte
│       └── register/+page.svelte
│
└── lib/
    ├── widgets/                    # Composite screen sections
    │   ├── sidebar/
    │   │   ├── Sidebar.svelte
    │   │   └── index.ts
    │   ├── task-list/              # Generic list (month/year/backlog/archive)
    │   │   ├── TaskList.svelte
    │   │   └── index.ts
    │   └── week-view/              # Week view: nav + week list + day grid + context
    │       ├── WeekView.svelte
    │       └── index.ts
    │
    ├── features/                   # User actions / orchestration
    │   ├── create-task/            # createTask() + CreateTaskForm.svelte (optimistic)
    │   ├── edit-task/              # EditTaskForm.svelte (optimistic upsert)
    │   ├── toggle-task/index.ts    # toggleTask(id) → done ↔ todo
    │   ├── replan-task/index.ts    # replanTask({ id, level, periodStart })
    │   └── update-profile/         # ProfileForm.svelte (patches userStore)
    │
    ├── entities/
    │   ├── user/
    │   │   ├── api/user.api.ts     # userApi.register / login / me
    │   │   ├── model/user.store.svelte.ts  # $state: user, loading; set/patch/clear
    │   │   └── index.ts
    │   └── task/
    │       ├── api/
    │       │   └── tasks.api.ts    # tasksApi.getAll / create / update / remove
    │       ├── model/
    │       │   ├── task.types.ts   # re-exports from @locus/shared
    │       │   └── task.store.svelte.ts  # $state store: tasks, loading, error
    │       ├── ui/                 # Dumb components (props only, no API calls)
    │       │   ├── TaskCard.svelte       # onToggle + onEdit props
    │       │   ├── TaskFormFields.svelte # Controlled dumb form (all fields, level-adaptive)
    │       │   └── TaskLevelBadge.svelte
    │       └── index.ts            # Public barrel export
    │
    └── shared/
        ├── ui/                     # shadcn-svelte components (added via CLI)
        ├── api/
        │   └── client.ts           # Base fetch wrapper: api.get/post/patch/delete
        └── lib/
            ├── utils.ts            # cn() = clsx + twMerge
            └── index.ts
```

---

## Aliases (svelte.config.js)

```js
'$widgets/*'  → 'src/lib/widgets/*'
'$features/*' → 'src/lib/features/*'
'$entities/*' → 'src/lib/entities/*'
'$shared/*'   → 'src/lib/shared/*'
// also without /* for barrel imports
```

---

## FSD Rules

### What belongs where

| Layer     | Create when                                        | Has                                   | Must NOT have               |
|-----------|----------------------------------------------------|---------------------------------------|-----------------------------|
| `entity`  | It's a business concept with its own data          | api, store, types, dumb UI components | deps on features or widgets |
| `feature` | It's a user action or orchestrates 2+ entities     | ui, optional store/composable         | own api, own data types     |
| `widget`  | It's a ready-made screen section                   | ui, optional local state              | direct API calls            |

**Quick check:**
- Entity → you own the data (types, store, API)
- Feature → user does an action, or logic pulls from 2+ entities
- Widget → assembles entity UI + features into one UI block

### Import direction

`routes → widgets → features → entities → shared` — downward only, never up.  
Slices at the same layer must not import each other — use `@x` instead.  
Each slice exposes a public API via `index.ts`.

### Cross-imports: `@x`

When entity A genuinely needs something from entity B, A creates `@x/b.ts` and re-exports **only** the minimum needed.

```
entities/task/@x/user.ts   → exports TaskType so user entity can reference tasks
entities/user/@x/task.ts   → exports useUserStore so task can check auth state
```

**Create `@x` only** for a real business need — never speculatively.

---

## Tailwind v4 Notes

- No `tailwind.config.js` — configuration lives in `app.css` via `@theme { ... }`
- Custom tokens defined in `@theme`: `--color-background`, `--color-accent`, etc.
- Vite plugin: `tailwindcss()` from `@tailwindcss/vite` (before `sveltekit()`)
- `app.css` starts with `@import "tailwindcss"` — no `@tailwind` directives

## shadcn-svelte Notes

- `components.json` configured to output to `$lib/shared/ui`
- Add components: `npx shadcn-svelte@latest add <component>`
- Components land in `src/lib/shared/ui/<component>/`

---

## State Management: Svelte 5 Runes

```ts
// entities/task/model/task.store.svelte.ts
const state = $state<State>({ tasks: [], loading: false, error: null })

export const taskStore = {
  get tasks() { return state.tasks },
  // mutators: setTasks, upsert, remove ...
}
```

- `$state` in `.svelte.ts` modules — reactive anywhere without `.subscribe()`
- `$derived` for computed values, `$effect` for side effects
- `$bindable()` only for two-way UI bindings in components

---

## Routing

```
/           → redirect → /today
/today      → Today view  (TaskView = 'day')  ← default
/week       → Week view   (WeekView widget: nav + list + day grid + context)
/month      → Month view
/year       → Year view
/backlog    → Backlog
/archive    → Archive
/settings   → Settings (profile + task config)
/login      → Login (auth group)
/register   → Register (auth group)
```

---

## Decisions

| Date       | Decision                                  | Reason                                      |
| 2026-05-03 | Added `overdue` to `TaskStatus` in shared | Spec uses it as DB status, store already filters by it |
| 2026-05-03 | `task.mocks.ts` in `entities/task/model/` | All 13 mock variants (all statuses × levels) seeded via `(app)/+layout.svelte` `onMount` |
| 2026-05-03 | Toggle is optimistic (no API dep)         | Lets UI work in mock mode; API update applied on top if available |
| 2026-05-03 | TaskFormFields — dumb with $bindable props | Parent holds state via $state, all fields level-adaptive, numerics kept as string |
| 2026-05-03 | Create/Edit inline in TaskList widget      | Widget owns open/close state; forms are feature components |
| 2026-05-03 | Settings route under (app)/settings        | Sidebar now accepts `AppView = TaskView \| 'settings'` |
| 2026-05-03 | Mock userStore seeded in layout onMount    | id='u1', name/email/timezone for ProfileForm |
| 2026-05-03 | routes/ renamed to pages/ (FSD naming)    | `kit.files.routes: 'src/pages'` in svelte.config.js |
| 2026-05-03 | WeekView widget — dedicated week page      | Separate from generic TaskList; owns weekOffset state, day grid, context sections |
| 2026-05-03 | /today as default view (TaskView='day')    | Shows tasks where targetDate=today; taskStore.getForDate() |
| 2026-05-03 | DAY_NAMES_SHORT, MONTH_NAMES_GENITIVE added | task.constants.ts — shared by WeekView and today page |
|------------|-------------------------------------------|---------------------------------------------|
| 2026-05-01 | SvelteKit 5 + Runes                       | Reactivity without boilerplate, SSR         |
| 2026-05-01 | FSD                                       | Scalable structure, clear layer boundaries  |
| 2026-05-01 | `.svelte.ts` stores                       | Svelte 5 runes work in .ts files            |
| 2026-05-01 | Tailwind v4 + @tailwindcss/vite           | No config file, CSS-native tokens           |
| 2026-05-01 | shadcn-svelte → `shared/ui`               | FSD: base UI primitives belong in shared    |
| 2026-05-01 | `cn()` = clsx + tailwind-merge            | Standard shadcn utility                     |
