<script lang="ts">
  import type { TaskLevel } from '../model/task.types'
  import { i18n } from '$shared/lib/i18n'

  type Props = { level: TaskLevel }
  const { level }: Props = $props()
</script>

<span class="level-badge level-{level}">{i18n.t(`level_short.${level}`)}</span>
