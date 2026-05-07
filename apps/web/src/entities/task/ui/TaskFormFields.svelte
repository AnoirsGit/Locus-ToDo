<script lang="ts">
  import type { TaskLevel } from '../model/task.types'

  const MONTH_NAMES = [
    'January','February','March','April','May','June',
    'July','August','September','October','November','December',
  ]
  const DOW_OPTIONS = [
    { value: '1', label: 'Monday' },    { value: '2', label: 'Tuesday' },
    { value: '3', label: 'Wednesday' }, { value: '4', label: 'Thursday' },
    { value: '5', label: 'Friday' },    { value: '6', label: 'Saturday' },
    { value: '0', label: 'Sunday' },
  ]

  type Props = {
    title: string; description: string; level: TaskLevel
    scheduledTime: string; targetDate: string; deadlineMonth: string
    recurring: boolean; dayOfWeek: string; dayOfMonth: string
    autoFocus?: boolean
  }

  let {
    title = $bindable(), description = $bindable(), level = $bindable(),
    scheduledTime = $bindable(), targetDate = $bindable(), deadlineMonth = $bindable(),
    recurring = $bindable(), dayOfWeek = $bindable(), dayOfMonth = $bindable(),
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
    <textarea
      bind:value={description}
      placeholder="Add a description…"
      rows="5"
      class="tform-desc"
    ></textarea>
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
        {#if recurring}
          <span class="tform-recurring-hint">{RECURRING_HINT[level]}</span>
        {/if}
      </div>
    </div>

    <!-- Week + recurring: day of week -->
    {#if recurring && level === 'week'}
      <div class="tform-row tform-row-sub">
        <div class="tform-field-label tform-sub-label">Every</div>
        <select bind:value={dayOfWeek} class="tform-control tform-select">
          <option value="">Monday (default)</option>
          {#each DOW_OPTIONS as d}<option value={d.value}>{d.label}</option>{/each}
        </select>
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
