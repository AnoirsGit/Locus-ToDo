# Current Task Context Refresh

## 1. Read

- Get current branch name via `git branch --show-current`
- Check `.claude/ai-ref-files/current/` for a file matching `<branch-name>.md`:
  - **Correct file exists** → read it and proceed
  - **Different file exists** → check if that branch is merged into master (`git branch --merged master`): if merged move it to `.claude/ai-ref-files/history/`, otherwise move it to `.claude/ai-ref-files/pending/`; then check `.claude/ai-ref-files/pending/<branch-name>.md` — if found, move it to `.claude/ai-ref-files/current/`; otherwise create `.claude/ai-ref-files/current/<branch-name>.md`
  - **No file exists** → check `.claude/ai-ref-files/pending/<branch-name>.md` — if found, move it to `.claude/ai-ref-files/current/`; otherwise create `.claude/ai-ref-files/current/<branch-name>.md`
- After creating a **new** branch file: check if the branch name clearly hints at the task (e.g. `BH-1234`, `fix-login`, `refactor-auth`). If it does not, ask the user: *"What is this branch about? Give me a brief description so I can plan the work."* — wait for the response before proceeding to plan.
- Read `.claude/PROJECT-REFERENCE.md` (project-wide reference, always) — if missing, review the project and create it
- Do NOT read `.claude/ai-ref-files/history/` — kept for archive, skip unless explicitly asked
- Proceed to orchestrated workflow below

> **Folder conventions:**
> - `.claude/ai-ref-files/current/` — one file: the active branch context
> - `.claude/ai-ref-files/pending/` — paused branches (unmerged, will return to); swapped in/out on branch changes
> - `.claude/ai-ref-files/history/` — merged or abandoned branches (permanent archive); only move here when a branch is explicitly closed/merged

---

# Workflow Orchestration

## 1. Plan Mode (Default)

- Enter plan mode for any non-trivial task (3+ steps or architectural decisions).
- If something goes sideways, STOP and re-plan immediately. Do not keep pushing.
- Use plan mode for verification steps, not just building.
- Write detailed specifications upfront to reduce ambiguity.

<!-- ## 2. Subagent Strategy

- Use subagents liberally to keep the main context window clean.
- Offload research, exploration, and parallel analysis to subagents.
- For complex problems, allocate more compute via subagents.
- One task per subagent for focused execution. -->

## 3. Self-Improvement Loop

- After any correction from the user, add a lessons section to `.claude/ai-ref-files/current/<branch-name>.md` with the pattern.
- Write rules to prevent repeating the same mistake.
- Iterate on lessons until the mistake rate drops.
- Review lessons at session start for relevant projects.

## 4. Verification Before Done

- Never mark a task complete without proving it works.
- Differentiate between main behavior and changes when relevant.
- Ask: "Would a staff engineer approve this?"
- Run tests, check logs, and demonstrate correctness.

## 5. Demand Elegance (Balanced)

- For non-trivial changes, pause and ask: "Is there a more elegant way?"
- If a fix feels hacky, reconsider and implement the elegant solution.
- Skip over-engineering for simple, obvious fixes.
- Challenge your own work before presenting it.

## 6. Autonomous Bug Fixing

- When given a bug report, fix it without requesting hand-holding.
- Identify logs, errors, and failing tests, then resolve them.
- Require zero context switching from the user.
- Fix failing CI tests proactively.

---

## Code Style

- **Arrow functions** — Use arrow functions. If it’s not an arrow function and doesn’t need special behavior (like its own this), rewrite it.
- **No unneeded comments** — Code must be understandable. Only comment complex business logic or hard-to-understand parts. Section-dividing comments are fine.
- **Use Type over Interfaces**

## Task Management

1. **Plan First** — Write plan to `.claude/ai-ref-files/current/<branch-name>.md` with checkable items. If the file is missing, create it using branch name as file name.
2. **Verify Plan** — Review and confirm before implementation.
3. **Track Progress** — Mark items complete as you proceed.
4. **Explain Changes** — Provide high-level summary at each step.
5. **Document Results** — Fill in the Resume section of `.claude/ai-ref-files/current/<branch-name>.md` with a short summary of what was done.
6. **Capture Lessons** — Add lessons section to `.claude/ai-ref-files/current/<branch-name>.md`.
7. **Branch Sync** — On any branch change mid-session, repeat the Read flow: check if the displaced branch is merged into master — if yes move its file to `.claude/ai-ref-files/history/`, if no move it to `.claude/ai-ref-files/pending/`. Then restore or create the new branch file in `.claude/ai-ref-files/current/`.

---

## Core Principles

- **Simplicity First** — Keep changes as simple as possible. Minimize impact.
- **No Laziness** — Identify root causes. Avoid temporary fixes. Maintain senior-level standards.
- **Minimal Impact** — Touch only what is necessary. Avoid introducing new bugs.