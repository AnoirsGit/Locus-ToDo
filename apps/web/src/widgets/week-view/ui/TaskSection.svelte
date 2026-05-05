<script lang="ts">
  import type { Snippet } from 'svelte';
  import { TaskCard } from '$entities/task';
  import type { TaskWithPeriod } from '$entities/task';

  let { 
    title, 
    tasks, 
    onToggle, 
    onEdit, 
    footer 
  } = $props<{
    title: string;
    tasks: TaskWithPeriod[];
    onToggle: (task: TaskWithPeriod) => void;
    onEdit?: (task: TaskWithPeriod) => void;
    footer?: Snippet;
  }>();
</script>

<section class="section">
  <div class="section-header">
    <h2 class="section-title">{title}</h2>
    <span class="section-meta">{tasks.length}</span>
  </div>
  <div class="task-list cards">
    {#each tasks as task (task.period.id)}
      <TaskCard
        {task}
        onToggle={onToggle}
        onEdit={onEdit}
      />
    {/each}
    {@render footer?.()}
  </div>
</section>
