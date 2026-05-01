<script lang="ts">
  import type { TaskView } from '@locus/shared'

  type Props = { currentView: TaskView }
  const { currentView }: Props = $props()

  const viewLabels: Record<TaskView, string> = {
    day: 'Сегодня',
    week: 'Эта неделя',
    month: 'Этот месяц',
    year: 'Этот год',
    backlog: 'Бэклог',
    archive: 'Архив',
  }
</script>

<section>
  <header>
    <h1>{viewLabels[currentView]}</h1>
  </header>
  <div class="content">
    <p class="placeholder">Задачи появятся здесь...</p>
  </div>
</section>

<style>
  section {
    flex: 1;
    display: flex;
    flex-direction: column;
    padding: 32px 40px;
    overflow-y: auto;
  }

  header {
    margin-bottom: 32px;
  }

  h1 {
    font-size: 1.6rem;
    font-weight: 700;
    letter-spacing: -0.5px;
  }

  .content {
    flex: 1;
  }

  .placeholder {
    color: var(--color-text-muted);
    font-size: 0.95rem;
  }
</style>
