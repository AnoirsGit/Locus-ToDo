<script lang="ts">
  import { page } from '$app/state'
  import { NotePage } from '$widgets/note-page'
</script>

<NotePage rootId={page.params.id ?? null} />
