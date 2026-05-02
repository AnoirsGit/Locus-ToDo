<script lang="ts">
  import type { TaskView } from '$entities/task'

  type Props = { currentView: TaskView }
  let { currentView = $bindable() }: Props = $props()
</script>

<!-- Sidebar UI — to be implemented -->
<aside>
  {currentView}
</aside>
