# arch/frontend.md

> Load when: web app (apps/web) — components, stores, routing, UI.

## Architecture: Feature-Sliced Design (FSD)

```
apps/web/src/
├── app/                 # App init, global styles
│   └── app.css
│
├── pages/               # Pages = SvelteKit routes
│   ├── (app)/           # Authenticated layout with sidebar
│   │   ├── +layout.svelte
│   │   ├── day/+page.svelte
│   │   ├── week/+page.svelte
│   │   ├── month/+page.svelte
│   │   ├── year/+page.svelte
│   │   ├── backlog/+page.svelte
│   │   └── archive/+page.svelte
│   └── (auth)/
│       ├── login/+page.svelte
│       └── register/+page.svelte
│
├── widgets/             # Composite UI blocks, not reusable in isolation
│   ├── sidebar/
│   │   └── Sidebar.svelte
│   └── task-board/
│       └── TaskBoard.svelte
│
├── features/            # User actions (create, complete, delete, send form, edit form)
│   ├── create-task/
│   │   ├── CreateTaskModal.svelte
│   │   └── create-task.ts       # UI-layer use case
│   ├── complete-task/
│   │   └── complete-task.ts
│   └── replan-task/
│       └── replan-task.ts
│
├── entities/            # Business objects and their UI representation
│   └── task/
│       ├── TaskCard.svelte      # Task card widget
│       ├── TaskLevel.svelte     # Level badge (📅/🗓️/🎯)
│       └── task.store.svelte.ts # $state-based task store
│
└── shared/              # Reusable with no domain context
    ├── ui/              # Base components (Button, Modal, Badge)
    ├── api/             # fetch wrappers for API
    │   └── tasks.api.ts
    └── lib/
        └── date.ts      # Date / deadline utilities
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

`pages → widgets → features → entities → shared` — downward only, never up.  
Slices at the same layer must not import each other — use `@x` instead.  

### Cross-imports: `@x`

When entity A genuinely needs something from entity B, A creates `@x/b.ts` and re-exports **only** the minimum needed. No broad re-exports.

```
entities/task/@x/user.ts    → exports TaskType so user entity can reference tasks
entities/user/@x/task.ts    → exports useUserStore so task can check auth state
```

Same pattern at widget level when a widget reuses an internal component of another widget.  
**Create `@x` only** for a real business need — never speculatively.

---
