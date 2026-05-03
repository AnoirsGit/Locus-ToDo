<script lang="ts">
  import type { TaskLevel } from '@locus/shared'
  import { MONTH_NAMES_FULL, DAYS_OF_WEEK_OPTIONS } from '../model/task.constants'
  import RichTextEditor from '$shared/ui/RichTextEditor.svelte'

  type Props = {
    title: string
    description: string
    level: TaskLevel
    targetDate: string
    deadlineMonth: string
    recurring: boolean
    dayOfWeek: string
    dayOfMonth: string
  }

  let {
    title = $bindable(),
    description = $bindable(),
    level = $bindable(),
    targetDate = $bindable(),
    deadlineMonth = $bindable(),
    recurring = $bindable(),
    dayOfWeek = $bindable(),
    dayOfMonth = $bindable(),
  }: Props = $props()

  const LEVEL_LABELS: Record<TaskLevel, string> = {
    day:   'День',
    week:  'Неделя',
    month: 'Месяц',
    year:  'Год',
  }

  const RECURRING_HINT: Record<TaskLevel, string> = {
    day:   'Новый период каждый день',
    week:  'Новый период каждую неделю',
    month: 'Новый период каждый месяц',
    year:  'Новый период каждый год',
  }

  const selectClass = 'w-full bg-gray-800 border border-gray-700 rounded-lg px-3 py-2 text-sm text-white outline-none focus:border-gray-500 transition-colors'
  const inputClass  = `${selectClass} placeholder:text-gray-600`
  const labelClass  = 'text-xs font-medium text-gray-500 mb-1 block'
</script>

<div class="flex gap-0">

  <!-- ── Left: title + description ──────────────────── -->
  <div class="flex-1 min-w-0 flex flex-col gap-4 p-5 border-r border-gray-800">
    <div>
      <input
        id="tf-title"
        type="text"
        bind:value={title}
        placeholder="Название задачи"
        class="w-full bg-transparent text-base font-medium text-white placeholder:text-gray-600 outline-none border-b border-gray-800 pb-2 focus:border-gray-600 transition-colors"
      />
    </div>
    <div class="flex-1">
      <RichTextEditor bind:value={description} />
    </div>
  </div>

  <!-- ── Right: parameters ──────────────────────────── -->
  <div class="w-52 flex-shrink-0 flex flex-col gap-4 p-4 bg-gray-900/50">

    <!-- Level -->
    <div>
      <span class={labelClass}>Уровень</span>
      <div class="flex flex-col gap-1">
        {#each (['day', 'week', 'month', 'year'] as const) as lvl}
          <button
            type="button"
            onclick={() => { level = lvl }}
            class="w-full text-left text-sm px-3 py-1.5 rounded-lg transition-colors select-none
              {level === lvl
                ? 'bg-gray-700 text-gray-100 font-medium'
                : 'text-gray-500 hover:text-gray-300 hover:bg-gray-800/60'}"
          >
            {LEVEL_LABELS[lvl]}
          </button>
        {/each}
      </div>
    </div>

    <!-- Week: target date -->
    {#if level === 'week'}
      <div>
        <label for="tf-target-date" class={labelClass}>Конкретный день</label>
        <input
          id="tf-target-date"
          type="date"
          bind:value={targetDate}
          class={inputClass}
        />
      </div>
    {/if}

    <!-- Year: deadline month -->
    {#if level === 'year'}
      <div>
        <label for="tf-deadline-month" class={labelClass}>Дедлайн (месяц)</label>
        <select id="tf-deadline-month" bind:value={deadlineMonth} class={selectClass}>
          <option value="">Без дедлайна</option>
          {#each MONTH_NAMES_FULL as m, i}
            <option value={String(i + 1)}>{m}</option>
          {/each}
        </select>
      </div>
    {/if}

    <!-- Recurring toggle -->
    <div>
      <span class={labelClass}>Повторение</span>
      <button
        type="button"
        role="switch"
        aria-checked={recurring}
        onclick={() => { recurring = !recurring }}
        class="w-full flex items-center justify-between px-3 py-1.5 rounded-lg border transition-colors select-none
          {recurring ? 'border-blue-700 bg-blue-900/20 text-blue-300' : 'border-gray-700 text-gray-500 hover:text-gray-300 hover:border-gray-600'}"
      >
        <span class="text-sm">{recurring ? 'Включено' : 'Выключено'}</span>
        <div class="relative w-8 h-4 rounded-full transition-colors {recurring ? 'bg-blue-600' : 'bg-gray-700'}">
          <span class="absolute top-0.5 w-3 h-3 bg-white rounded-full shadow transition-all {recurring ? 'left-4' : 'left-0.5'}"></span>
        </div>
      </button>
      {#if recurring}
        <p class="text-xs text-gray-600 mt-1.5 px-1">{RECURRING_HINT[level]}</p>
      {/if}
    </div>

    <!-- Week + recurring: day of week -->
    {#if recurring && level === 'week'}
      <div>
        <label for="tf-day-of-week" class={labelClass}>День создания</label>
        <select id="tf-day-of-week" bind:value={dayOfWeek} class={selectClass}>
          <option value="">Начало недели (Пн)</option>
          {#each DAYS_OF_WEEK_OPTIONS as d}
            <option value={d.value}>{d.label}</option>
          {/each}
        </select>
      </div>
    {/if}

    <!-- Month + recurring: day of month -->
    {#if recurring && level === 'month'}
      <div>
        <label for="tf-day-of-month" class={labelClass}>Число месяца</label>
        <input
          id="tf-day-of-month"
          type="text"
          inputmode="numeric"
          bind:value={dayOfMonth}
          placeholder="1"
          class={inputClass}
        />
      </div>
    {/if}

  </div>
</div>
