<script lang="ts">
  import type { TaskLevel } from '../model/task.types'

  type Props = { level: TaskLevel }
  const { level }: Props = $props()

  const labels: Record<TaskLevel, string> = {
    day: 'День', week: 'Нед', month: 'Мес', year: 'Год',
  }
</script>

<span class="level-badge level-{level}">{labels[level]}</span>
