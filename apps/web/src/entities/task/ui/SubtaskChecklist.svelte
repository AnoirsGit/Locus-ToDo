<script lang="ts">
  import type { TaskWithPeriod, TaskLevel, TaskStatus } from '../model/task.types'
  import { tasksApi } from '../api/tasks.api'

  type Props = {
    parentTaskId: string
    parentLevel: TaskLevel
    parentPeriodStart: string
  }
  const { parentTaskId, parentLevel, parentPeriodStart }: Props = $props()

  let items   = $state<TaskWithPeriod[]>([])
  let loading = $state(true)
  let adding  = $state(false)
  let newTitle = $state('')

  // Load subtasks on mount
  const load = async () => {
    loading = true
    try {
      items = await tasksApi.getSubtasks(parentTaskId)
    } catch {
      items = []
    } finally {
      loading = false
    }
  }

  $effect(() => {
    load()
  })

  const toggle = async (item: TaskWithPeriod) => {
    const cur = item.period.status as TaskStatus
    const next: TaskStatus = cur === 'done' ? 'todo' : 'done'
    // Optimistic
    items = items.map(t =>
      t.period.id === item.period.id
        ? { ...t, period: { ...t.period, status: next, doneAt: next === 'done' ? new Date().toISOString() : undefined } }
        : t
    )
    try {
      await tasksApi.updatePeriod(item.period.id, { status: next })
    } catch {
      await load() // revert on error
    }
  }

  const addSubtask = async () => {
    const title = newTitle.trim()
    if (!title) return
    adding = true
    try {
      const created = await tasksApi.create({
        title,
        level: parentLevel,
        periodStart: parentPeriodStart,
        parentTaskId,
      })
      items = [...items, created]
      newTitle = ''
    } catch {
      // toast fires automatically via API client
    } finally {
      adding = false
    }
  }

  const handleKeydown = (e: KeyboardEvent) => {
    if (e.key === 'Enter') addSubtask()
    if (e.key === 'Escape') { newTitle = ''; (e.target as HTMLElement).blur() }
  }
</script>

<div class="subtask-list">
  {#if loading}
    <div class="subtask-loading">...</div>
  {:else}
    {#each items as item (item.period.id)}
      {@const done = item.period.status === 'done'}
      <label class="subtask-row">
        <button
          class="subtask-check"
          class:checked={done}
          onclick={() => toggle(item)}
          aria-label={done ? 'Unmark' : 'Mark done'}
          type="button"
        >
          {#if done}
            <svg viewBox="0 0 10 10" fill="none">
              <path d="M1.5 5l2.5 2.5L8.5 2" stroke="currentColor" stroke-width="1.6"
                stroke-linecap="round" stroke-linejoin="round"/>
            </svg>
          {/if}
        </button>
        <span class="subtask-title" class:done>{item.title}</span>
      </label>
    {/each}

    <div class="subtask-add-row">
      <div class="subtask-check add-btn"></div>
      <input
        class="subtask-input"
        type="text"
        placeholder="Add subtask…"
        bind:value={newTitle}
        onkeydown={handleKeydown}
        disabled={adding}
      />
      {#if newTitle.trim()}
        <button class="subtask-save" onclick={addSubtask} disabled={adding} type="button">
          <svg width="10" height="10" viewBox="0 0 10 10" fill="none">
            <path d="M1.5 5l2.5 2.5L8.5 2" stroke="currentColor" stroke-width="1.8"
              stroke-linecap="round" stroke-linejoin="round"/>
          </svg>
        </button>
      {/if}
    </div>
  {/if}
</div>
