<script lang="ts">
  import { TaskCard } from '$entities/task';
  import type { TaskWithPeriod } from '$entities/task';
  import { tagStore } from '$entities/tag';
  import { i18n } from '$shared/lib/i18n';
  import { toLocalISO } from '$shared/lib/date';

  let {
    day,
    tasks,
    isToday,
    onToggle,
    onEdit,
    onQuickCreate,
    onOpenModal,
    onDropTask
  } = $props<{
    day: Date;
    tasks: TaskWithPeriod[];
    isToday: boolean;
    onToggle: (task: TaskWithPeriod) => void;
    onEdit: (task: TaskWithPeriod) => void;
    onQuickCreate: (title: string, date: string) => Promise<void>;
    onOpenModal: (date: string) => void;
    onDropTask: (periodId: string, date: string) => void;
  }>();

  let quickCreateActive = $state(false);
  let quickTitle = $state('');
  let dragOver = $state(false);

  // Only week-level tasks can be re-dropped onto another day (their targetDate is
  // editable via the API). Day tasks have no periodStart update path, so they don't drag.
  const onCardDragStart = (e: DragEvent, periodId: string) => {
    e.dataTransfer?.setData('text/plain', periodId);
    if (e.dataTransfer) e.dataTransfer.effectAllowed = 'move';
  };

  const onColDragOver = (e: DragEvent) => {
    e.preventDefault();
    if (e.dataTransfer) e.dataTransfer.dropEffect = 'move';
    dragOver = true;
  };

  const onColDrop = (e: DragEvent) => {
    e.preventDefault();
    dragOver = false;
    const periodId = e.dataTransfer?.getData('text/plain');
    if (periodId) onDropTask(periodId, dateKey);
  };
  
  const dateKey = $derived(toLocalISO(day));
  const dowLabel = $derived(new Intl.DateTimeFormat(i18n.locale, { weekday: 'short' }).format(day));

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

<div
  class="day-col w-[85vw] md:w-52 shrink-0"
  class:drag-over={dragOver}
  data-date={dateKey}
  role="list"
  ondragover={onColDragOver}
  ondragleave={() => (dragOver = false)}
  ondrop={onColDrop}
>
  <div class="day-col-header" class:today={isToday}>
    <span class="day-col-dow">{dowLabel}</span>
    <span class="day-col-num" class:today={isToday}>{day.getDate()}</span>
  </div>
  <div class="day-col-body">
    {#each tasks as task (task.period.id)}
      {#if task.level === 'week'}
        <div
          class="kanban-draggable"
          draggable="true"
          role="listitem"
          ondragstart={(e) => onCardDragStart(e, task.period.id)}
        >
          <TaskCard
            {task}
            onToggle={onToggle}
            onEdit={onEdit}
            showLevel={false}
            tags={tagStore.getTagsForTask(task.id)}
          />
        </div>
      {:else}
        <TaskCard
          {task}
          onToggle={onToggle}
          onEdit={onEdit}
          showLevel={false}
          tags={tagStore.getTagsForTask(task.id)}
        />
      {/if}
    {/each}

    {#if quickCreateActive}
      <div class="day-col-card-input flex items-center gap-1">
        <input
          type="text"
          bind:value={quickTitle}
          onkeydown={handleKeydown}
          placeholder="Task name…"
          autofocus
          class="day-col-input flex-1"
        />
        <button
          type="button"
          class="btn-icon shrink-0"
          aria-label="Open full form"
          onclick={() => { quickCreateActive = false; quickTitle = ''; onOpenModal(dateKey); }}
        >
          <svg class="w-3.5 h-3.5" viewBox="0 0 16 16" fill="none">
            <path d="M10 2h4v4M14 2l-5 5M6 14H2v-4M2 14l5-5" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
          </svg>
        </button>
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

<style>
  .day-col.drag-over {
    outline: 2px dashed var(--color-day);
    outline-offset: -2px;
    border-radius: 8px;
    background: var(--color-day-tint);
  }
  .kanban-draggable { cursor: grab; }
  .kanban-draggable:active { cursor: grabbing; }
</style>
