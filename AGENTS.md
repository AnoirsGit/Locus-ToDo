# AGENTS.md — repo notes for future sessions

## Mobile bug/gap-fixing sweep (2026-07-27, continued from earlier 07-16 session)

Source plans: `.claude/ai-ref-files/current/{bugs.md,mobile-tasks-parity.md,qol-polish.md}`.
Scope: mobile Flutter app only (`apps/mobile`), i18n explicitly excluded, push
directly to `main` (no PRs).

### Status as of commit `4cc881e`

**Done** (mobile-tasks-parity.md Gaps 1–4, 6; bugs.md B3/B4; qol-polish.md B/D items):
- Gap 1: tag filter bar on all `/view` screens (today/week-kanban/generic), not just backlog/archive
- Gap 2: subtask checklist expander on task cards
- Gap 3: stats year history + prepended "current" trend row
- Gap 4: kanban day-column create is date-bound (creates on the tapped day, not today)
- Gap 6: archived/backlog cards show period label + done-at date / backlog age
- B3: `AppShell.didChangeAppLifecycleState` refetches grouped-tasks providers on
  resume, throttled ≥60s (mirrors web's `visibilitychange` handler)
- B4: `appToastProvider` (ScaffoldMessenger-based) wired into every *discrete*
  mutation across tasks/notes (create/update/delete/replan) + subtask CRUD inside
  `TaskFormSheet`. Micro-edits (note reorder/indent/collapse/content-debounce,
  task toggle) are intentionally silent — they go through an offline outbox/sync
  worker (`sync_worker.dart` / `notes_sync_worker.dart`) with retry + a pending-sync
  banner in `AppShell`, not a per-edit toast. Don't add toasts to those paths —
  it was a deliberate design split (irreversible/structural ops = toast,
  fire-and-forget queued edits = banner), not an oversight.
- TaskFormSheet: dirty-dismiss confirm (PopScope + X-button guard), drag handle,
  keyboard-avoidance via `viewInsets.bottom` — all already present.
- Notes: pull-to-refresh, backspace-delete-empty-block, debounced-save flush on
  app backgrounding (`inactive`/`paused`/`hidden`).
- Skeleton loaders (`shared/ui/skeleton.dart`: `Skeleton`/`TaskListSkeleton`/
  `StatsSkeleton`) replacing bare `CircularProgressIndicator` on view/tasks/notes/stats.
- Haptics on task create/save success + delete confirm (cards already had them).
- `TaskCard` title strike-through now animates via `AnimatedDefaultTextStyle`.
- Filtered-to-empty state (tag filter hides all tasks) shows "no match" +
  clear-filter button instead of the generic "create task" empty state, on both
  `view_tab_page.dart` and `tasks_page.dart`.
- Double-submit guards verified fine by design: `TaskFormSheet._submit()` pops
  the sheet synchronously before any async call, so a second tap can't land.

**Deliberately skipped**: everything under Gap 5 (i18n) and bugs.md's hardcoded-
string/locale items (they're all i18n-flavored) — per explicit user instruction
this session.

**Not yet done** (lower priority / bigger scope, if resuming):
- bugs.md B1: mobile `date_utils.dart` helper dedup (mobile is *already correct*
  behaviorally — local `DateTime.now()` — this is just a code-dedup nice-to-have,
  not a live bug)
- qol-polish.md D: true `AnimatedList`-based item insertion/removal animations
  across the tasks lists — not attempted; current lists are plain `ListView` +
  `.map()`, not `ListView.builder` with keys, so this would be a real refactor
  with regression risk, not a quick win. Swipe-delete (Dismissible) and the
  strike-through/checkbox already animate.
- qol-polish.md G: dev date/time mock widget, seed-data script — dev tooling,
  out of mobile-app scope for this pass.

### Session 2 additions (commits `4cc881e`..`0922d08`)

- B4 stragglers closed: `authNotifier.updateProfile` had zero error handling
  (exception thrown into a fire-and-forget `onPressed` after the dialog was
  already closed — user saw nothing); Settings > Tags create/delete had the
  same silent-noop-on-failure shape. Both now toast via `appToastProvider`.
- **Real bug found & fixed**: `register_page.dart`'s submit button computed
  `disabled` from `_nameController.text` inside `build()`, but nothing
  triggered a rebuild on keystroke (no `onChanged`/listener on that
  `TextField`) — the button could stay stuck disabled regardless of what the
  user typed, until some unrelated rebuild happened to fire. Fixed by adding
  `onChanged: (_) => setState(() {})` to all three fields + a proper
  `_formValid` getter (name/email non-empty, password ≥ 8 — matches the API's
  `zod .min(8)`). **If you touch any other form with a `Controller.text`-based
  `onPressed: ... ? null : ...` gate, verify a rebuild trigger exists** —
  `TaskFormSheet`'s title field already does this correctly
  (`onChanged: (_) => setState(() {})` at the TextField), so it was spared;
  this was an isolated instance, not a pattern.
- Login/register: `authState.error.toString()` was rendered straight to the
  UI (raw `DioException [bad response]: ...` text). Added
  `shared/core/auth_error.dart::formatAuthError()` (401/409/422/network-
  timeout → short Russian messages) and wired both pages to it.
- qol-polish.md F polish: show/hide password toggle + autofocus first field
  on both auth pages; min-8-chars password hint on register.
- Housekeeping: `.agents_tmp/` (agent scratch dir) got swept into a commit by
  a wildcard `git add -A` — removed from tracking, added to `.gitignore`.
  **Don't `git add -A` blindly in this repo; check `git status` first.**

### Environment gotcha
This workspace runs multiple parallel checkouts of the same repo under
`/workspace/project/<uuid>/Locus-ToDo`. If a working directory suddenly reports
"No such file or directory" mid-session, don't panic — check `/workspace/project/*/Locus-ToDo`
for a sibling checkout, verify true `origin/main` state via `GET /repos/.../commits?sha=main`
(GitHub API) rather than trusting any single checkout's stale local refs, then
resume in whichever checkout is closest to that HEAD. `flutter`/`dart` are not
installed in this environment — verify edits via paren/brace balance checks
(`s.count('(')-s.count(')')` etc.) rather than `flutter analyze`.
