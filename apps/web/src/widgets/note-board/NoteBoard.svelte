<script lang="ts">
  import type { NoteNode } from '$entities/note'
  import { noteStore } from '$entities/note'

  // Top-level nodes become columns; their children become cards
  const columns = $derived(noteStore.rootNodes)

  let editingId = $state<string | null>(null)

  const typeLabel: Record<string, string> = {
    text: 'Text', heading1: 'H1', heading2: 'H2',
    bullet: '·', image: 'Img', link: '↗',
  }
</script>

<div class="note-board">
  {#if noteStore.loaded && columns.length === 0}
    <div class="note-board-empty">
      <svg width="36" height="36" viewBox="0 0 36 36" fill="none" opacity="0.35">
        <rect x="2" y="4" width="9" height="28" rx="2" stroke="currentColor" stroke-width="1.5"/>
        <rect x="13.5" y="4" width="9" height="20" rx="2" stroke="currentColor" stroke-width="1.5"/>
        <rect x="25" y="4" width="9" height="24" rx="2" stroke="currentColor" stroke-width="1.5"/>
      </svg>
      <span>No columns yet — add one to get started</span>
    </div>
  {/if}

  {#each columns as col (col.id)}
    <div class="note-board-col">
      <!-- Column header = top-level node -->
      <div class="note-board-col-header">
        {#if editingId === col.id}
          <input
            class="note-board-col-input"
            value={col.content}
            autofocus
            oninput={(e) => noteStore.update(col.id, { content: (e.target as HTMLInputElement).value })}
            onblur={() => editingId = null}
            onkeydown={(e) => e.key === 'Enter' && (editingId = null)}
          />
        {:else}
          <button
            class="note-board-col-title"
            onclick={() => editingId = col.id}
          >
            {col.content || 'Untitled'}
          </button>
        {/if}
        <span class="note-board-col-count">{col.children.length}</span>
      </div>

      <!-- Cards = children of column -->
      <div class="note-board-cards">
        {#each col.children as card (card.id)}
          <div class="note-board-card">
            <div class="note-board-card-type">{typeLabel[card.type] ?? card.type}</div>

            {#if card.type === 'image' && card.url}
              <img src={card.url} alt={card.content} class="note-board-card-img" />
            {/if}

            {#if editingId === card.id}
              <input
                class="note-board-card-input"
                value={card.content}
                autofocus
                oninput={(e) => noteStore.update(card.id, { content: (e.target as HTMLInputElement).value })}
                onblur={() => editingId = null}
                onkeydown={(e) => e.key === 'Enter' && (editingId = null)}
              />
            {:else}
              <button
                class="note-board-card-content"
                onclick={() => editingId = card.id}
              >
                {card.content || 'Empty'}
              </button>
            {/if}

            {#if card.type === 'link' && card.url}
              <a href={card.url} target="_blank" rel="noopener" class="note-board-card-link">
                {card.url}
              </a>
            {/if}

            <!-- Nested count badge -->
            {#if card.children.length > 0}
              <span class="note-board-card-nested">{card.children.length} nested</span>
            {/if}
          </div>
        {/each}

        <!-- Add card button -->
        <button
          class="note-board-add-card"
          onclick={async () => {
            const lastChild = col.children.at(-1)
            if (lastChild) {
              const newCard = await noteStore.addAfter(lastChild.id)
              editingId = newCard.id
            } else {
              // Column has no children yet — add a root node then indent under col
              const newCard = await noteStore.addAfter(col.id)
              noteStore.indent(newCard.id)
              editingId = newCard.id
            }
          }}
        >
          <svg width="10" height="10" viewBox="0 0 10 10" fill="none">
            <path d="M5 1v8M1 5h8" stroke="currentColor" stroke-width="1.4" stroke-linecap="round"/>
          </svg>
          Add card
        </button>
      </div>
    </div>
  {/each}

  <!-- Add column (always shown, acts as CTA when empty too) -->
  <button
    class="note-board-add-col"
    onclick={async () => {
      const node = await noteStore.addRoot()
      editingId = node.id
    }}
  >
    <svg width="12" height="12" viewBox="0 0 12 12" fill="none">
      <path d="M6 1v10M1 6h10" stroke="currentColor" stroke-width="1.5" stroke-linecap="round"/>
    </svg>
    Add column
  </button>
</div>

<style>
  .note-board-empty {
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 12px;
    padding: 64px 32px;
    color: var(--color-muted);
    width: 280px;
  }

  .note-board-empty span {
    font-size: 13px;
    text-align: center;
  }
</style>
