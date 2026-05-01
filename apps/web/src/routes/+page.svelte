<script lang="ts">
  import type { TaskView } from '@locus/shared'
  import Board from '$components/Board.svelte'
  import Sidebar from '$components/Sidebar.svelte'

  let currentView = $state<TaskView>('week')
</script>

<Sidebar bind:currentView />
<Board {currentView} />
