<script lang="ts">
  import type { TaskLevel } from '../model/task.types'

  const MONTH_NAMES = ['Январь','Февраль','Март','Апрель','Май','Июнь',
                       'Июль','Август','Сентябрь','Октябрь','Ноябрь','Декабрь']
  const DOW_OPTIONS = [
    { value: '1', label: 'Понедельник' }, { value: '2', label: 'Вторник' },
    { value: '3', label: 'Среда' },       { value: '4', label: 'Четверг' },
    { value: '5', label: 'Пятница' },     { value: '6', label: 'Суббота' },
    { value: '0', label: 'Воскресенье' },
  ]

  type Props = {
    title: string; description: string; level: TaskLevel
    scheduledTime: string; targetDate: string; deadlineMonth: string
    recurring: boolean; dayOfWeek: string; dayOfMonth: string
  }

  let {
    title = $bindable(), description = $bindable(), level = $bindable(),
    scheduledTime = $bindable(), targetDate = $bindable(), deadlineMonth = $bindable(),
    recurring = $bindable(), dayOfWeek = $bindable(), dayOfMonth = $bindable(),
  }: Props = $props()

  const LEVEL_LABELS: Record<TaskLevel, string> = { day: 'День', week: 'Неделя', month: 'Месяц', year: 'Год' }
  const RECURRING_HINT: Record<TaskLevel, string> = {
    day:   'Новый период каждый день',
    week:  'Новый период каждую неделю',
    month: 'Новый период каждый месяц',
    year:  'Новый период каждый год',
  }
</script>

<div class="flex min-h-0">
  <!-- Left: title + description -->
  <div class="flex-1 min-w-0 flex flex-col gap-4 p-5 border-r border-border">
    <input
      type="text"
      bind:value={title}
      placeholder="Название задачи"
      class="w-full bg-transparent outline-none pb-2 font-medium text-base transition-colors text-text-strong border-b border-border"
    />
    <textarea
      bind:value={description}
      placeholder="Описание (необязательно)"
      rows="5"
      class="input resize-none"
    ></textarea>
  </div>

  <!-- Right: parameters -->
  <div class="w-52 shrink-0 flex flex-col gap-4 p-4 overflow-y-auto">

    <!-- Level -->
    <div>
      <span class="label">Уровень</span>
      <div class="flex flex-col">
        {#each (['day', 'week', 'month', 'year'] as const) as lvl}
          <button
            type="button"
            onclick={() => { level = lvl }}
            class="chip"
            class:active={level === lvl}
            class:level-day={level === lvl && lvl === 'day'}
            class:level-week={level === lvl && lvl === 'week'}
            class:level-month={level === lvl && lvl === 'month'}
            class:level-year={level === lvl && lvl === 'year'}
          >{LEVEL_LABELS[lvl]}</button>
        {/each}
      </div>
    </div>

    <!-- Time (day and week) -->
    {#if level === 'day' || level === 'week'}
      <div>
        <label for="tf-time" class="label">
          Время <span class="text-muted-2 font-inherit font-normal normal-case tracking-normal">(необязательно)</span>
        </label>
        <input id="tf-time" type="time" step="900" bind:value={scheduledTime} class="input" />
      </div>
    {/if}

    <!-- Target date (week only) -->
    {#if level === 'week'}
      <div>
        <label for="tf-target-date" class="label">Конкретный день</label>
        <input id="tf-target-date" type="date" bind:value={targetDate} class="input" />
      </div>
    {/if}

    <!-- Deadline month (year only) -->
    {#if level === 'year'}
      <div>
        <label for="tf-deadline-month" class="label">Дедлайн (месяц)</label>
        <select id="tf-deadline-month" bind:value={deadlineMonth} class="input">
          <option value="">Без дедлайна</option>
          {#each MONTH_NAMES as m, i}
            <option value={String(i + 1)}>{m}</option>
          {/each}
        </select>
      </div>
    {/if}

    <!-- Recurring toggle -->
    <div>
      <span class="label">Повторение</span>
      <div class="flex items-center justify-between gap-3">
        <span class="text-sm text-muted">{recurring ? 'Включено' : 'Выключено'}</span>
        <button
          type="button"
          class="switch"
          class:on={recurring}
          onclick={() => { recurring = !recurring }}
          aria-label="Переключить повторение"
        ></button>
      </div>
      {#if recurring}
        <p class="text-xs mt-1.5 text-muted">{RECURRING_HINT[level]}</p>
      {/if}
    </div>

    <!-- Week + recurring: day of week -->
    {#if recurring && level === 'week'}
      <div>
        <label for="tf-dow" class="label">Выходит каждый</label>
        <select id="tf-dow" bind:value={dayOfWeek} class="input">
          <option value="">Понедельник (по умолчанию)</option>
          {#each DOW_OPTIONS as d}<option value={d.value}>{d.label}</option>{/each}
        </select>
        {#if dayOfWeek || scheduledTime}
          <p class="text-xs mt-1.5 text-muted">
            Каждый {dayOfWeek ? DOW_OPTIONS.find(d => d.value === dayOfWeek)?.label ?? 'Пн' : 'Понедельник'}
            {#if scheduledTime} в {scheduledTime}{/if}
          </p>
        {/if}
      </div>
    {/if}

    <!-- Month + recurring: day of month -->
    {#if recurring && level === 'month'}
      <div>
        <label for="tf-dom" class="label">Число месяца</label>
        <input id="tf-dom" type="text" inputmode="numeric" bind:value={dayOfMonth} placeholder="1" class="input w-24" />
      </div>
    {/if}

  </div>
</div>
