<script lang="ts">
  import type { TaskLevel } from '$entities/task'

  type Props = { level: TaskLevel }
  const { level }: Props = $props()

  const config: Record<TaskLevel, { label: string; cls: string }> = {
    day:   { label: 'День', cls: 'border-gray-500  text-gray-400'   },
    week:  { label: 'Нед',  cls: 'border-blue-500  text-blue-400'   },
    month: { label: 'Мес',  cls: 'border-purple-500 text-purple-400' },
    year:  { label: 'Год',  cls: 'border-yellow-500 text-yellow-400' },
  }
</script>

<span class="inline-flex items-center px-1.5 py-0.5 rounded border text-xs font-medium {config[level].cls}">
  {config[level].label}
</span>
