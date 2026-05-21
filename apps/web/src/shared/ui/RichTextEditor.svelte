<script lang="ts">
  import { onMount, onDestroy } from 'svelte'
  import { Editor } from '@tiptap/core'
  import StarterKit from '@tiptap/starter-kit'
  import TaskList from '@tiptap/extension-task-list'
  import TaskItem from '@tiptap/extension-task-item'
  import Placeholder from '@tiptap/extension-placeholder'
  import Link from '@tiptap/extension-link'

  type Props = {
    value: string
    placeholder?: string
    minHeight?: string
  }

  let { value = $bindable(), placeholder = 'Add a description…', minHeight = '120px' }: Props = $props()

  let mount: HTMLElement   // Tiptap mounts its ProseMirror div here
  let editor: Editor | null = null

  let active = $state({
    bold: false, italic: false, strike: false,
    bulletList: false, orderedList: false, taskList: false,
  })

  const syncActive = (e: Editor) => {
    active = {
      bold:        e.isActive('bold'),
      italic:      e.isActive('italic'),
      strike:      e.isActive('strike'),
      bulletList:  e.isActive('bulletList'),
      orderedList: e.isActive('orderedList'),
      taskList:    e.isActive('taskList'),
    }
  }

  onMount(() => {
    editor = new Editor({
      element: mount,
      injectCSS: false,        // we provide all styles ourselves
      injectNonce: undefined,
      extensions: [
        StarterKit.configure({
          heading: false, codeBlock: false,
          code: false, blockquote: false,
          horizontalRule: false,
        }),
        TaskList,
        TaskItem.configure({ nested: true }),
        Placeholder.configure({ placeholder }),
        Link.configure({ openOnClick: false }),
      ],
      content: value || '',
      editorProps: {
        attributes: {
          class: 'tiptap',
          style: `min-height:${minHeight}`,
        },
      },
      onUpdate({ editor: e }) {
        value = e.isEmpty ? '' : e.getHTML()
        syncActive(e)
      },
      onSelectionUpdate({ editor: e }) { syncActive(e) },
    })
  })

  onDestroy(() => { editor?.destroy() })

  // Use onmousedown + preventDefault so the editor never loses focus
  const btn = (fn: () => void) => (e: MouseEvent) => {
    e.preventDefault()
    fn()
  }
</script>

<div class="rte">
  <div class="rte-bar">
    <button type="button" class="rte-btn" class:on={active.bold}
      onmousedown={btn(() => editor?.chain().focus().toggleBold().run())}
      title="Bold (Ctrl+B)"><strong>B</strong></button>

    <button type="button" class="rte-btn rte-btn-i" class:on={active.italic}
      onmousedown={btn(() => editor?.chain().focus().toggleItalic().run())}
      title="Italic (Ctrl+I)"><em>I</em></button>

    <button type="button" class="rte-btn rte-btn-s" class:on={active.strike}
      onmousedown={btn(() => editor?.chain().focus().toggleStrike().run())}
      title="Strikethrough (Ctrl+Shift+X)"><s>S</s></button>

    <span class="rte-sep"></span>

    <!-- Bullet list -->
    <button type="button" class="rte-btn" class:on={active.bulletList}
      onmousedown={btn(() => editor?.chain().focus().toggleBulletList().run())}
      title="Bullet list">
      <svg viewBox="0 0 16 16" fill="none" width="13" height="13">
        <circle cx="2.5" cy="4.5" r="1.5" fill="currentColor"/>
        <circle cx="2.5" cy="8" r="1.5" fill="currentColor"/>
        <circle cx="2.5" cy="11.5" r="1.5" fill="currentColor"/>
        <path d="M6 4.5h8M6 8h8M6 11.5h8" stroke="currentColor" stroke-width="1.5" stroke-linecap="round"/>
      </svg>
    </button>

    <!-- Ordered list -->
    <button type="button" class="rte-btn" class:on={active.orderedList}
      onmousedown={btn(() => editor?.chain().focus().toggleOrderedList().run())}
      title="Numbered list">
      <svg viewBox="0 0 16 16" fill="none" width="13" height="13">
        <path d="M2 3h1.5v4" stroke="currentColor" stroke-width="1.3" stroke-linecap="round" stroke-linejoin="round"/>
        <path d="M1.5 7h2" stroke="currentColor" stroke-width="1.3" stroke-linecap="round"/>
        <path d="M1.5 10h2c.5 0 .5 1-.1 1H1.5M1.5 13h2.5" stroke="currentColor" stroke-width="1.3" stroke-linecap="round" stroke-linejoin="round"/>
        <path d="M6 4h8M6 8h8M6 12h8" stroke="currentColor" stroke-width="1.5" stroke-linecap="round"/>
      </svg>
    </button>

    <!-- Checklist -->
    <button type="button" class="rte-btn" class:on={active.taskList}
      onmousedown={btn(() => editor?.chain().focus().toggleTaskList().run())}
      title="Checklist">
      <svg viewBox="0 0 16 16" fill="none" width="13" height="13">
        <rect x="1.5" y="2.5" width="5" height="5" rx="1" stroke="currentColor" stroke-width="1.3"/>
        <path d="M3 5l1.2 1.2 2.3-2" stroke="currentColor" stroke-width="1.3" stroke-linecap="round" stroke-linejoin="round"/>
        <rect x="1.5" y="9.5" width="5" height="5" rx="1" stroke="currentColor" stroke-width="1.3"/>
        <path d="M9 5h5.5M9 12h5.5" stroke="currentColor" stroke-width="1.5" stroke-linecap="round"/>
      </svg>
    </button>
  </div>

  <!-- Tiptap mounts its own div.ProseMirror inside here -->
  <div class="rte-mount">
    <div bind:this={mount}></div>
  </div>
</div>

<style>
  .rte {
    border: 1px solid var(--color-border);
    border-radius: var(--r-md);
    overflow: hidden;
    transition: border-color 120ms;
    background: var(--color-card);
  }
  .rte:focus-within { border-color: var(--color-border-2); }

  /* Toolbar */
  .rte-bar {
    display: flex; align-items: center; gap: 2px;
    padding: 5px 8px;
    border-bottom: 1px solid var(--color-border);
    background: var(--color-surface);
  }

  .rte-btn {
    display: flex; align-items: center; justify-content: center;
    width: 28px; height: 26px; padding: 0;
    border: none; border-radius: var(--r-sm);
    background: transparent; color: var(--color-muted);
    cursor: pointer; font-size: 13px; font-family: inherit;
    flex-shrink: 0; transition: background 80ms, color 80ms;
  }
  .rte-btn:hover { background: var(--color-surface-2); color: var(--color-text); }
  .rte-btn.on    { background: var(--color-surface-2); color: var(--color-text-strong); }
  .rte-btn-i em  { font-style: italic; }
  .rte-btn-s s   { text-decoration: line-through; }

  .rte-sep {
    width: 1px; height: 16px; flex-shrink: 0;
    background: var(--color-border); margin: 0 4px;
  }

  /* Mount wrapper — padding lives here */
  .rte-mount { padding: 10px 12px; cursor: text; }
</style>
