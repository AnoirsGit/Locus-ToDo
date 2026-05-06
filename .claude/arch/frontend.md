# arch/frontend.md

> Load when: web app (apps/web) — components, stores, routing, UI.

## Stack

SvelteKit 2.x · Svelte 5 (runes) · Tailwind CSS v4 (with tailwind.config.ts) · TypeScript

---

## FSD Structure

```
apps/web/src/
  app.html / app.css        # Entry HTML + @theme tokens + design system classes
  pages/                    # SvelteKit routes (kit.files.routes = 'src/pages')
    (app)/                  # Authenticated shell
      +layout.svelte        # Sidebar + main wrapper, seeds userStore
      today/                # Default view: day tasks (target_date = today)
      week/                 # WeekView widget
      month/ year/ backlog/ archive/ settings/
    (auth)/                 # login/ register/
  widgets/
    sidebar/                # Nav + theme toggle + user card
    task-list/              # Generic list for month/year/backlog/archive
    task-modal/             # Create/edit modal wrapper
    week-view/              # Kanban day grid (WeekHeader, DayColumn, TaskSection)
  features/
    create-task/            # createTask() + CreateTaskForm
    edit-task/              # EditTaskForm
    toggle-task/            # toggleTask() — optimistic
    replan-task/            # replanTask()
    update-profile/         # ProfileForm
  entities/
    task/                   # TaskCard, TaskLevelBadge, TaskFormFields, taskStore, tasksApi, mocks
    user/                   # userStore (no UI)
  shared/
    api/                    # fetch client, auth.api.ts, tasks.api.ts
    ui/                     # RichTextEditor
```

Aliases: `$widgets/*`, `$features/*`, `$entities/*`, `$shared/*`

---

## FSD Rules

Import direction: `pages → widgets → features → entities → shared` — downward only.
Same-layer slices must not import each other. Each slice exports via `index.ts`.

---

## State

Svelte 5 runes in `.svelte.ts` modules. `taskStore` is the central reactive store.
Views filter `taskStore.items` via `$derived`.

```ts
const state = $state<State>({ items: [], loading: false })
export const taskStore = { get items() { return state.items }, ... }
```

---

## Theme

Dual CSS custom property theme via `data-theme` attribute on `<html>`.
- `light` — paper/ink, Fraunces serif
- `dark` — same structure, dark neutral palette

Stored in `localStorage('theme')`. Anti-FOUC inline script in `app.html`.
Design system classes in `app.css`: `.task`, `.btn`, `.sidebar`, `.modal`, `.auth-wrap`, etc.

---

## Routes

```
/           → redirect → /today
/today      → day tasks (target_date filter) + week/month/year context (goals)
/week       → WeekView (nav + week list + day grid + context)
/month /year /backlog /archive → TaskList widget
/settings   → ProfileForm + task config
/login /register → auth pages
```

---

## Key Decisions

| Decision | Reason |
|----------|--------|
| Svelte 5 runes | Reactivity without boilerplate |
| FSD | Clear layer boundaries, consistent with mobile |
| Tailwind v4 config | Link design tokens from `colors.ts` to Tailwind utilities |
| Optimistic toggle | Instant UI, API applied on top |
| Frontend-first with mocks | Ship UI before API is ready |
| Responsive Grid Layout | Use CSS Grid for task lists on desktop (min 300px per card) to optimize space |
| `kit.files.routes: 'src/pages'` | FSD naming for routes dir |
| TaskFormFields — dumb `$bindable` | Parent owns state; form is just UI |
