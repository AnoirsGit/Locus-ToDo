<script lang="ts">
  import { onMount } from 'svelte'
  import { Editor } from '@tiptap/core'
  import StarterKit from '@tiptap/starter-kit'
  import Placeholder from '@tiptap/extension-placeholder'

  type Props = {
    value: string
    placeholder?: string
  }

  let { value = $bindable(''), placeholder = 'Описание...' }: Props = $props()

  let editorEl: HTMLDivElement
  let editor: Editor | null = null

  onMount(() => {
    editor = new Editor({
      element: editorEl,
      extensions: [
        StarterKit,
        Placeholder.configure({ placeholder }),
      ],
      content: value || '',
      editorProps: {
        attributes: {
          class: 'prose-editor focus:outline-none min-h-[72px] text-sm text-white',
        },
      },
      onUpdate: ({ editor: e }) => {
        const html = e.isEmpty ? '' : e.getHTML()
        if (html !== value) value = html
      },
    })

    return () => editor?.destroy()
  })

  const cmd = (action: () => boolean) => () => {
    action()
    editor?.view.focus()
  }

  const active = (check: () => boolean) => editor && check()
</script>

<div class="flex flex-col border border-gray-700 rounded overflow-hidden bg-gray-800 focus-within:border-gray-500 transition-colors">
  <!-- Toolbar -->
  <div class="flex items-center gap-0.5 px-1.5 py-1 border-b border-gray-700">
    <button
      type="button"
      title="Жирный (Ctrl+B)"
      class="toolbar-btn"
      class:active={active(() => editor!.isActive('bold'))}
      onclick={cmd(() => editor!.chain().focus().toggleBold().run())}
    >
      <svg class="w-3.5 h-3.5" viewBox="0 0 14 14" fill="currentColor">
        <path d="M3 2h4.5a3 3 0 0 1 0 6H3V2zm0 6h5a3 3 0 0 1 0 6H3V8z"/>
      </svg>
    </button>

    <button
      type="button"
      title="Курсив (Ctrl+I)"
      class="toolbar-btn"
      class:active={active(() => editor!.isActive('italic'))}
      onclick={cmd(() => editor!.chain().focus().toggleItalic().run())}
    >
      <svg class="w-3.5 h-3.5" viewBox="0 0 14 14" fill="currentColor">
        <path d="M5 2h6M3 12h6M8 2 6 12" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" fill="none"/>
      </svg>
    </button>

    <button
      type="button"
      title="Зачёркнутый"
      class="toolbar-btn"
      class:active={active(() => editor!.isActive('strike'))}
      onclick={cmd(() => editor!.chain().focus().toggleStrike().run())}
    >
      <svg class="w-3.5 h-3.5" viewBox="0 0 14 14" fill="none">
        <path d="M2 7h10M4 4.5C4 3.1 5.3 2 7 2s3 1.1 3 2.5c0 .7-.3 1.3-.8 1.7M4.5 9.5C4.7 11 5.7 12 7 12c1.7 0 3-1.1 3-2.5" stroke="currentColor" stroke-width="1.3" stroke-linecap="round"/>
      </svg>
    </button>

    <div class="w-px h-4 bg-gray-700 mx-0.5"></div>

    <button
      type="button"
      title="Маркированный список"
      class="toolbar-btn"
      class:active={active(() => editor!.isActive('bulletList'))}
      onclick={cmd(() => editor!.chain().focus().toggleBulletList().run())}
    >
      <svg class="w-3.5 h-3.5" viewBox="0 0 14 14" fill="none">
        <circle cx="2.5" cy="4" r="1" fill="currentColor"/>
        <circle cx="2.5" cy="8" r="1" fill="currentColor"/>
        <circle cx="2.5" cy="12" r="1" fill="currentColor"/>
        <path d="M5 4h7M5 8h7M5 12h7" stroke="currentColor" stroke-width="1.3" stroke-linecap="round"/>
      </svg>
    </button>

    <button
      type="button"
      title="Нумерованный список"
      class="toolbar-btn"
      class:active={active(() => editor!.isActive('orderedList'))}
      onclick={cmd(() => editor!.chain().focus().toggleOrderedList().run())}
    >
      <svg class="w-3.5 h-3.5" viewBox="0 0 14 14" fill="none">
        <path d="M1.5 2.5h2M1.5 2.5V5M5 4h7M5 8h7M5 12h7" stroke="currentColor" stroke-width="1.3" stroke-linecap="round"/>
        <path d="M1.5 7.5c0-.8.7-1 1-.5.3.5-.5 1.5-1.5 2h2" stroke="currentColor" stroke-width="1.1" stroke-linecap="round" stroke-linejoin="round"/>
        <path d="M1.5 11h2M2.5 11v2H1.5" stroke="currentColor" stroke-width="1.2" stroke-linecap="round" stroke-linejoin="round"/>
      </svg>
    </button>

    <div class="w-px h-4 bg-gray-700 mx-0.5"></div>

    <button
      type="button"
      title="Код"
      class="toolbar-btn"
      class:active={active(() => editor!.isActive('code'))}
      onclick={cmd(() => editor!.chain().focus().toggleCode().run())}
    >
      <svg class="w-3.5 h-3.5" viewBox="0 0 14 14" fill="none">
        <path d="M4 3 1 7l3 4M10 3l3 4-3 4" stroke="currentColor" stroke-width="1.3" stroke-linecap="round" stroke-linejoin="round"/>
      </svg>
    </button>
  </div>

  <!-- Editor area -->
  <div
    bind:this={editorEl}
    class="px-2.5 py-2 cursor-text"
  ></div>
</div>

<style>
  .toolbar-btn {
    display: flex;
    align-items: center;
    justify-content: center;
    width: 1.75rem;
    height: 1.75rem;
    border-radius: 0.25rem;
    color: var(--color-gray-400, #9ca3af);
    transition: background-color 0.1s, color 0.1s;
  }

  .toolbar-btn:hover {
    background-color: var(--color-gray-700, #374151);
    color: var(--color-white, #fff);
  }

  .toolbar-btn.active {
    background-color: var(--color-gray-700, #374151);
    color: var(--color-white, #fff);
  }

  :global(.prose-editor p) { margin: 0 0 0.25rem; }
  :global(.prose-editor p:last-child) { margin-bottom: 0; }
  :global(.prose-editor ul) { padding-left: 1.25rem; list-style: disc; margin: 0.25rem 0; }
  :global(.prose-editor ol) { padding-left: 1.25rem; list-style: decimal; margin: 0.25rem 0; }
  :global(.prose-editor code) { background: #1f2937; border-radius: 0.2rem; padding: 0.1rem 0.3rem; font-family: monospace; font-size: 0.8em; }
  :global(.prose-editor strong) { font-weight: 600; }
  :global(.prose-editor em) { font-style: italic; }
  :global(.prose-editor s) { text-decoration: line-through; }
  :global(.prose-editor .is-editor-empty:first-child::before) {
    content: attr(data-placeholder);
    color: #4b5563;
    pointer-events: none;
    float: left;
    height: 0;
  }
</style>
