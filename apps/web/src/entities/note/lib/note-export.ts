import type { NoteNode } from '../model/note.types'

// ── Markdown ─────────────────────────────────────────────────────────────────

const mdLine = (node: NoteNode, depth: number): string => {
  const pad = '  '.repeat(depth)
  switch (node.type) {
    case 'heading1': return `${'#'.repeat(1)} ${node.content}`
    case 'heading2': return `${'#'.repeat(2)} ${node.content}`
    case 'todo':     return `${pad}- [${node.done ? 'x' : ' '}] ${node.content}`
    case 'link':     return `${pad}- [${node.content || node.url || ''}](${node.url ?? ''})`
    case 'image':    return `${pad}- ![${node.content}](${node.url ?? ''})`
    case 'text':     return `${pad}${node.content}`
    default:         return `${pad}- ${node.content}`
  }
}

const mdWalk = (nodes: NoteNode[], depth: number, out: string[]) => {
  for (const n of nodes) {
    out.push(mdLine(n, depth))
    if (n.children.length) mdWalk(n.children, depth + 1, out)
  }
}

export const toMarkdown = (nodes: NoteNode[]): string => {
  const out: string[] = []
  mdWalk(nodes, 0, out)
  return out.join('\n') + '\n'
}

// ── OPML ─────────────────────────────────────────────────────────────────────

const xmlEscape = (s: string): string =>
  s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;')

const opmlOutline = (nodes: NoteNode[], depth: number, out: string[]) => {
  const pad = '  '.repeat(depth + 2)
  for (const n of nodes) {
    const attrs = [`text="${xmlEscape(n.content)}"`, `_type="${n.type}"`]
    if (n.url) attrs.push(`_url="${xmlEscape(n.url)}"`)
    if (n.type === 'todo') attrs.push(`_done="${n.done ? 'true' : 'false'}"`)
    if (n.children.length) {
      out.push(`${pad}<outline ${attrs.join(' ')}>`)
      opmlOutline(n.children, depth + 1, out)
      out.push(`${pad}</outline>`)
    } else {
      out.push(`${pad}<outline ${attrs.join(' ')}/>`)
    }
  }
}

export const toOpml = (nodes: NoteNode[]): string => {
  const out: string[] = [
    '<?xml version="1.0" encoding="UTF-8"?>',
    '<opml version="2.0">',
    '  <head><title>Locus notes</title></head>',
    '  <body>',
  ]
  opmlOutline(nodes, 0, out)
  out.push('  </body>', '</opml>', '')
  return out.join('\n')
}

// ── Download trigger ─────────────────────────────────────────────────────────

export const downloadText = (filename: string, text: string, mime: string) => {
  const blob = new Blob([text], { type: mime })
  const url = URL.createObjectURL(blob)
  const a = document.createElement('a')
  a.href = url
  a.download = filename
  a.click()
  URL.revokeObjectURL(url)
}
