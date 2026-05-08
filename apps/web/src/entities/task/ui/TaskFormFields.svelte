<script lang="ts">
  import type { TaskLevel, TaskWithPeriod } from '../model/task.types'
  import RichTextEditor from '$shared/ui/RichTextEditor.svelte'

  const MONTH_NAMES = [
    'January','February','March','April','May','June',
    'July','August','September','October','November','December',
  ]

  // Mon-first order: value = JS DOW (0=Sun,1=Mon…), label = short name
  const DOW_OPTIONS = [
    { value: 1, label: 'Mon' }, { value: 2, label: 'Tue' },
    { value: 3, label: 'Wed' }, { value: 4, label: 'Thu' },
    { value: 5, label: 'Fri' }, { value: 6, label: 'Sat' },
    { value: 0, label: 'Sun' },
  ]

  type Props = {
    title: string
    description: string
    level: TaskLevel
    scheduledTime: string
    targetDate: string
    deadlineMonth: string
    recurring: boolean
    daysOfWeek: number[]
    dayOfMonth: string
    // Subtasks — only used in edit mode
    subtasks?: TaskWithPeriod[]
    onAddSubtask?: (title: string) => Promise<void>
    onToggleSubtask?: (periodId: string) => void
    onDeleteSubtask?: (taskId: string) => Promise<void>
    autoFocus?: boolean
  }

  let {
    title = $bindable(),
    description = $bindable(),
    level = $bindable(),
    scheduledTime = $bindable(),
    targetDate = $bindable(),
    deadlineMonth = $bindable(),
    recurring = $bindable(),
    daysOfWeek = $bindable(),
    dayOfMonth = $bindable(),
    subtasks,
    onAddSubtask,
    onToggleSubtask,
    onDeleteSubtask,
    autoFocus = true,
  }: Props = $props()

  const LEVELS: { value: TaskLevel; label: string }[] = [
    { value: 'day',   label: 'Day'   },
    { value: 'week',  label: 'Week'  },
    { value: 'month', label: 'Month' },
    { value: 'year',  label: 'Year'  },
  ]

  const RECURRING_HINT: Record<TaskLevel, string> = {
    day:   'Every day',
    week:  'Every week',
    month: 'Every month',
    year:  'Every year',
  }

  function toggleDay(dow: number) {
    if (daysOfWeek.includes(dow)) {
      daysOfWeek = daysOfWeek.filter((d) => d !== dow)
    } else if (daysOfWeek.length < 6) {
      daysOfWeek = [...daysOfWeek, dow]
    }
  }

  let newSubtaskTitle = $state('')
  let addingSubtask = $state(false)

  async function submitSubtask() {
    const t = newSubtaskTitle.trim()
    if (!t || !onAddSubtask) return
    await onAddSubtask(t)
    newSubtaskTitle = ''
    addingSubtask = false
  }
</script>

<div class="tform">

  <!-- Left: title + description -->
  <div class="tform-left">
    <input
      type="text"
      bind:value={title}
      placeholder="Task title"
      class="tform-title"
      autofocus={autoFocus}
      autocomplete="off"
    />
    <RichTextEditor bind:value={description} minHeight="120px" />

    <!-- Subtasks (edit mode only) -->
    {#if subtasks !== undefined}
      <div class="tform-subtasks">
        <div class="tform-subtasks-header">
          <span class="tform-sub-heading">Subtasks</span>
          {#if subtasks.length > 0}
            <span class="tform-sub-count">{subtasks.filter(s => s.period.status === 'done').length}/{subtasks.length}</span>
          {/if}
        </div>

        {#each subtasks as sub (sub.period.id)}
          <div class="tform-subtask-row">
            <button
              type="button"
              class="checkbox checkbox-sm"
              class:checked={sub.period.status === 'done'}
              onclick={() => onToggleSubtask?.(sub.period.id)}
              aria-label={sub.period.status === 'done' ? 'Unmark' : 'Mark done'}
            >
              {#if sub.period.status === 'done'}
                <svg class="checkbox-tick" viewBox="0 0 10 10" fill="none">
                  <path d="M1.5 5l2.5 2.5L8.5 2" stroke="currentColor" stroke-width="1.6"
                    stroke-linecap="round" stroke-linejoin="round"/>
                </svg>
              {/if}
            </button>
            <span class="tform-subtask-title" class:done={sub.period.status === 'done'}>{sub.title}</span>
            {#if onDeleteSubtask}
              <button
                type="button"
                class="tform-subtask-del"
                onclick={() => onDeleteSubtask!(sub.id)}
                aria-label="Delete subtask"
              >
                <svg viewBox="0 0 12 12" fill="none" width="10" height="10">
                  <path d="M2 2l8 8M10 2l-8 8" stroke="currentColor" stroke-width="1.4" stroke-linecap="round"/>
                </svg>
              </button>
            {/if}
          </div>
        {/each}

        {#if addingSubtask}
          <div class="tform-subtask-add-row">
            <!-- svelte-ignore a11y_autofocus -->
            <input
              type="text"
              bind:value={newSubtaskTitle}
              placeholder="Subtask title…"
              class="tform-subtask-input"
              autofocus
              onkeydown={(e) => { if (e.key === 'Enter') { e.preventDefault(); submitSubtask() } if (e.key === 'Escape') addingSubtask = false }}
            />
            <button type="button" class="btn-icon" onclick={submitSubtask}>
              <svg viewBox="0 0 12 12" fill="none" width="12" height="12">
                <path d="M1 6h10M7 2l4 4-4 4" stroke="currentColor" stroke-width="1.4" stroke-linecap="round" stroke-linejoin="round"/>
              </svg>
            </button>
            <button type="button" class="btn-icon" onclick={() => addingSubtask = false}>
              <svg viewBox="0 0 12 12" fill="none" width="10" height="10">
                <path d="M2 2l8 8M10 2l-8 8" stroke="currentColor" stroke-width="1.4" stroke-linecap="round"/>
              </svg>
            </button>
          </div>
        {:else if onAddSubtask}
          <button type="button" class="tform-add-subtask" onclick={() => addingSubtask = true}>
            <svg viewBox="0 0 12 12" fill="none" width="11" height="11">
              <path d="M6 1v10M1 6h10" stroke="currentColor" stroke-width="1.5" stroke-linecap="round"/>
            </svg>
            Add subtask
          </button>
        {/if}
      </div>
    {/if}
  </div>

  <!-- Right: details panel -->
  <div class="tform-right">

    <div class="tform-panel-label">Details</div>

    <!-- Level -->
    <div class="tform-row">
      <div class="tform-field-label">
        <svg class="tform-icon" viewBox="0 0 16 16" fill="none">
          <rect x="2" y="2" width="5" height="5" rx="1" stroke="currentColor" stroke-width="1.4"/>
          <rect x="9" y="2" width="5" height="5" rx="1" stroke="currentColor" stroke-width="1.4"/>
          <rect x="2" y="9" width="5" height="5" rx="1" stroke="currentColor" stroke-width="1.4"/>
          <rect x="9" y="9" width="5" height="5" rx="1" stroke="currentColor" stroke-width="1.4"/>
        </svg>
        Level
      </div>
      <div class="tform-level-pills">
        {#each LEVELS as lvl}
          <button
            type="button"
            onclick={() => { level = lvl.value }}
            class="level-pill"
            class:active={level === lvl.value}
            data-level={lvl.value}
          >{lvl.label}</button>
        {/each}
      </div>
    </div>

    <!-- Time (day and week) -->
    {#if level === 'day' || level === 'week'}
      <div class="tform-row">
        <div class="tform-field-label">
          <svg class="tform-icon" viewBox="0 0 16 16" fill="none">
            <circle cx="8" cy="8" r="6" stroke="currentColor" stroke-width="1.4"/>
            <path d="M8 5v3l2 2" stroke="currentColor" stroke-width="1.4" stroke-linecap="round"/>
          </svg>
          Time
        </div>
        <input type="time" step="900" bind:value={scheduledTime} class="tform-control" />
      </div>
    {/if}

    <!-- Target date (week only) -->
    {#if level === 'week'}
      <div class="tform-row">
        <div class="tform-field-label">
          <svg class="tform-icon" viewBox="0 0 16 16" fill="none">
            <rect x="2" y="3" width="12" height="11" rx="1.5" stroke="currentColor" stroke-width="1.4"/>
            <path d="M5 2v2M11 2v2M2 7h12" stroke="currentColor" stroke-width="1.4" stroke-linecap="round"/>
          </svg>
          Target day
        </div>
        <input type="date" bind:value={targetDate} class="tform-control" />
      </div>
    {/if}

    <!-- Deadline month (year only) -->
    {#if level === 'year'}
      <div class="tform-row">
        <div class="tform-field-label">
          <svg class="tform-icon" viewBox="0 0 16 16" fill="none">
            <path d="M2 12l4-4 3 3 5-6" stroke="currentColor" stroke-width="1.4" stroke-linecap="round" stroke-linejoin="round"/>
          </svg>
          Deadline
        </div>
        <select bind:value={deadlineMonth} class="tform-control tform-select">
          <option value="">No deadline</option>
          {#each MONTH_NAMES as m, i}
            <option value={String(i + 1)}>{m}</option>
          {/each}
        </select>
      </div>
    {/if}

    <!-- Recurring toggle -->
    <div class="tform-row">
      <div class="tform-field-label">
        <svg class="tform-icon" viewBox="0 0 16 16" fill="none">
          <path d="M13 5H6a3 3 0 000 6h7" stroke="currentColor" stroke-width="1.4" stroke-linecap="round"/>
          <path d="M11 3l2 2-2 2" stroke="currentColor" stroke-width="1.4" stroke-linecap="round" stroke-linejoin="round"/>
          <path d="M3 11H10a3 3 0 000-6H3" stroke="currentColor" stroke-width="1.4" stroke-linecap="round"/>
          <path d="M5 13l-2-2 2-2" stroke="currentColor" stroke-width="1.4" stroke-linecap="round" stroke-linejoin="round"/>
        </svg>
        Recurring
      </div>
      <div class="tform-recurring-wrap">
        <button
          type="button"
          class="switch"
          class:on={recurring}
          onclick={() => { recurring = !recurring }}
          aria-label="Toggle recurring"
        ></button>
        {#if recurring && level !== 'week'}
          <span class="tform-recurring-hint">{RECURRING_HINT[level]}</span>
        {/if}
      </div>
    </div>

    <!-- Week + recurring: multi-day chip selector -->
    {#if recurring && level === 'week'}
      <div class="tform-row tform-row-sub">
        <div class="tform-field-label tform-sub-label">Days</div>
        <div class="tform-dow-chips">
          {#each DOW_OPTIONS as d}
            <button
              type="button"
              class="tform-dow-chip"
              class:selected={daysOfWeek.includes(d.value)}
              class:maxed={!daysOfWeek.includes(d.value) && daysOfWeek.length >= 6}
              onclick={() => toggleDay(d.value)}
              title={daysOfWeek.length >= 6 && !daysOfWeek.includes(d.value) ? 'Max 6 days' : ''}
            >{d.label}</button>
          {/each}
        </div>
      </div>
    {/if}

    <!-- Month + recurring: day of month -->
    {#if recurring && level === 'month'}
      <div class="tform-row tform-row-sub">
        <div class="tform-field-label tform-sub-label">Day of month</div>
        <input
          type="text"
          inputmode="numeric"
          bind:value={dayOfMonth}
          placeholder="1"
          class="tform-control"
          style="width: 60px"
        />
      </div>
    {/if}

  </div>
</div>
