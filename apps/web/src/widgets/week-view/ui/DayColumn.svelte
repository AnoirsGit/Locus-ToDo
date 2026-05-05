<script lang="ts">
  import { TaskCard } from '$entities/task';
  import type { TaskWithPeriod } from '$entities/task';
  import { DAY_NAMES_SHORT } from '$entities/task';

  let { 
    day, 
    tasks, 
    isToday, 
    onToggle, 
    onEdit, 
    onQuickCreate,
    onOpenModal
  } = $props<{
    day: Date;
    tasks: TaskWithPeriod[];
    isToday: boolean;
    onToggle: (task: TaskWithPeriod) => void;
    onEdit: (task: TaskWithPeriod) => void;
    onQuickCreate: (title: string, date: string) => Promise<void>;
    onOpenModal: (date: string) => void;
  }>();

  let quickCreateActive = $state(false);
  let quickTitle = $state('');
  
  const dateKey = day.toISOString().split('T')[0];

  async function submitQuickCreate() {
    const t = quickTitle.trim();
    if (!t) { quickCreateActive = false; return; }
    quickCreateActive = false;
    const titleToSubmit = quickTitle;
    quickTitle = '';
    await onQuickCreate(titleToSubmit, dateKey);
  }

  function handleKeydown(e: KeyboardEvent) {
    if (e.key === 'Enter') { e.preventDefault(); submitQuickCreate(); }
    if (e.key === 'Escape') { quickCreateActive = false; quickTitle = ''; }
  }
</script>

<div class="day-col w-[85vw] md:w-52 shrink-0" data-date={dateKey}>
  <div class="day-col-header" class:today={isToday}>
    <span class="day-col-dow">{DAY_NAMES_SHORT[day.getDay()]}</span>
    <span class="day-col-num" class:today={isToday}>{day.getDate()}</span>
  </div>
  <div class="day-col-body">
    {#each tasks as task (task.period.id)}
      <TaskCard
        {task}
        onToggle={onToggle}
        onEdit={onEdit}
        showLevel={false}
      />
    {/each}

    {#if quickCreateActive}
      <div class="day-col-card-input">
        <input
          type="text"
          bind:value={quickTitle}
          onkeydown={handleKeydown}
          placeholder="Task name…"
          autofocus
          class="day-col-input"
        />
      </div>
    {:else}
      <button
        class="day-col-add-card"
        onclick={() => { quickCreateActive = true; quickTitle = ''; }}
      >
        <span class="day-col-add-plus">+</span> Add task
      </button>
    {/if}
  </div>
</div>
