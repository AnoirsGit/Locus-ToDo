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


  const inputClass = 'bg-gray-800 border border-gray-700 rounded px-2 py-1.5 text-sm text-white placeholder:text-gray-600 w-full'
  const labelClass = 'text-xs text-gray-400'
</script>

<div class="flex flex-col gap-2.5">
  <!-- Level -->
  <div class="flex flex-col gap-1">
    <label for="tf-level" class={labelClass}>Уровень</label>
    <select id="tf-level" bind:value={level} class={inputClass}>
      <option value="day">День</option>
      <option value="week">Неделя</option>
      <option value="month">Месяц</option>
      <option value="year">Год</option>
    </select>
  </div>

  <!-- Title -->
  <div class="flex flex-col gap-1">
    <label for="tf-title" class={labelClass}>Название <span class="text-red-500">*</span></label>
    <input
      id="tf-title"
      type="text"
      bind:value={title}
      placeholder="Название задачи"
      class={inputClass}
    />
  </div>

  <!-- Description -->
  <div class="flex flex-col gap-1">
    <label class={labelClass}>Описание</label>
    <RichTextEditor bind:value={description} />
  </div>

  <!-- targetDate — week only -->
  {#if level === 'week'}
    <div class="flex flex-col gap-1">
      <label for="tf-target-date" class={labelClass}>Плановая дата</label>
      <input
        id="tf-target-date"
        type="date"
        bind:value={targetDate}
        class={inputClass}
      />
    </div>
  {/if}

  <!-- deadlineMonth — year only -->
  {#if level === 'year'}
    <div class="flex flex-col gap-1">
      <label for="tf-deadline-month" class={labelClass}>Месяц дедлайна</label>
      <select id="tf-deadline-month" bind:value={deadlineMonth} class={inputClass}>
        <option value="">Без дедлайна</option>
        {#each MONTH_NAMES_FULL as m, i}
          <option value={String(i + 1)}>{m}</option>
        {/each}
      </select>
    </div>
  {/if}

  <!-- Recurring toggle -->
  <div class="flex items-center gap-2">
    <input id="tf-recurring" type="checkbox" bind:checked={recurring} class="accent-gray-400 w-3.5 h-3.5" />
    <label for="tf-recurring" class={labelClass}>Повторяющаяся задача</label>
  </div>

  <!-- dayOfWeek — week + recurring -->
  {#if recurring && level === 'week'}
    <div class="flex flex-col gap-1">
      <label for="tf-day-of-week" class={labelClass}>День недели</label>
      <select id="tf-day-of-week" bind:value={dayOfWeek} class={inputClass}>
        <option value="">Начало недели</option>
        {#each DAYS_OF_WEEK_OPTIONS as d}
          <option value={d.value}>{d.label}</option>
        {/each}
      </select>
    </div>
  {/if}

  <!-- dayOfMonth — month + recurring -->
  {#if recurring && level === 'month'}
    <div class="flex flex-col gap-1">
      <label for="tf-day-of-month" class={labelClass}>День месяца (1–31)</label>
      <input
        id="tf-day-of-month"
        type="text"
        inputmode="numeric"
        bind:value={dayOfMonth}
        placeholder="1"
        class="{inputClass} w-24"
      />
    </div>
  {/if}
</div>
