<script lang="ts">
  import type { TaskView } from '$entities/task'

  type Props = { view: TaskView }
  const { view }: Props = $props()
</script>

<!-- TaskList UI — to be implemented -->
<section>{view}</section>
