# Branch: front-initial

## Plan: Forms + Settings + Week/Today Views

### Phase 1 — Forms & Settings ✅
- [x] Create `entities/user` — userStore with patch()
- [x] Create `entities/task/ui/TaskFormFields.svelte` — dumb controlled form fields
- [x] Modify `entities/task/ui/TaskCard.svelte` — add edit button (onEdit prop)
- [x] Extract constants → `entities/task/model/task.constants.ts`
- [x] Modify `features/create-task/index.ts` — optimistic upsert + expanded input
- [x] Create `features/create-task/ui/CreateTaskForm.svelte`
- [x] Create `features/edit-task/index.ts` + ui/EditTaskForm.svelte
- [x] Create `features/update-profile/index.ts` + ui/ProfileForm.svelte
- [x] Modify `widgets/task-list/TaskList.svelte` — inline create/edit
- [x] Modify `widgets/sidebar/Sidebar.svelte` — Settings + Сегодня links
- [x] Create `pages/(app)/settings/+page.svelte`
- [x] Modify `pages/(app)/+layout.svelte` — seed userStore

### Phase 2 — Week/Today Views ✅
- [x] Rename `routes/` → `pages/` (svelte.config.js: kit.files.routes)
- [x] Add `DAY_NAMES_SHORT`, `MONTH_NAMES_GENITIVE` to task.constants.ts
- [x] Add `taskStore.getForDate(date)` for today view
- [x] Create `widgets/week-view/WeekView.svelte` — nav + week list + day grid + context
- [x] Update `pages/(app)/week/+page.svelte` → uses WeekView
- [x] Create `pages/(app)/today/+page.svelte` — default view
- [x] Root redirect `/` → `/today`

## Resume
All mock-mode views implemented. 0 svelte-check errors, 13 warnings (all pre-existing).

## Lessons
- `$bindable()` in Svelte 5: use string state in form, convert to typed values at submit boundary
- Circular dep risk: feature ui component MUST NOT import from its own slice's index.ts
- Entity constants (MONTH_NAMES_*, DAY_NAMES_SHORT) live in `entities/task/model/task.constants.ts`
- `$derived.by(() => { ... })` for multi-line derivations in Svelte 5
- SvelteKit routes dir is configurable via `kit.files.routes` — rename to `pages/` works cleanly
