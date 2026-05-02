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
│   ├── +page.svelte                # Redirects → /week
│   ├── (app)/                      # Authenticated shell
│   │   ├── +layout.svelte          # Sidebar + main wrapper
│   │   ├── week/+page.svelte
│   │   ├── month/+page.svelte
│   │   ├── year/+page.svelte
│   │   ├── backlog/+page.svelte
│   │   └── archive/+page.svelte
│   └── (auth)/
│       ├── login/+page.svelte
│       └── register/+page.svelte
│
└── lib/
    ├── widgets/                    # Composite screen sections
    │   ├── sidebar/
    │   │   ├── Sidebar.svelte
    │   │   └── index.ts
    │   └── task-list/
    │       ├── TaskList.svelte
    │       └── index.ts
    │
    ├── features/                   # User actions / orchestration
    │   ├── create-task/index.ts    # createTask(input) → calls entity api + store
    │   ├── toggle-task/index.ts   # toggleTask(id) → done ↔ todo
    │   └── replan-task/index.ts    # replanTask({ id, level, periodStart })
    │
    ├── entities/
    │   └── task/
    │       ├── api/
    │       │   └── tasks.api.ts    # tasksApi.getAll / create / update / remove
    │       ├── model/
    │       │   ├── task.types.ts   # re-exports from @locus/shared
    │       │   └── task.store.svelte.ts  # $state store: tasks, loading, error
    │       ├── ui/                 # Dumb components (props only, no API calls)
    │       │   ├── TaskCard.svelte
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
/           → redirect → /week
/week       → Week view
/month      → Month view
/year       → Year view
/backlog    → Backlog
/archive    → Archive
/login      → Login (auth group)
/register   → Register (auth group)
```

---

## Decisions

| Date       | Decision                                  | Reason                                      |
|------------|-------------------------------------------|---------------------------------------------|
| 2026-05-01 | SvelteKit 5 + Runes                       | Reactivity without boilerplate, SSR         |
| 2026-05-01 | FSD                                       | Scalable structure, clear layer boundaries  |
| 2026-05-01 | `.svelte.ts` stores                       | Svelte 5 runes work in .ts files            |
| 2026-05-01 | Tailwind v4 + @tailwindcss/vite           | No config file, CSS-native tokens           |
| 2026-05-01 | shadcn-svelte → `shared/ui`               | FSD: base UI primitives belong in shared    |
| 2026-05-01 | `cn()` = clsx + tailwind-merge            | Standard shadcn utility                     |
