export type NoteNodeType = 'text' | 'heading1' | 'heading2' | 'bullet' | 'image' | 'link' | 'todo'

export type NoteNode = {
  id: string
  type: NoteNodeType
  content: string       // text label / paragraph body
  url?: string          // image src or link href
  children: NoteNode[]
  collapsed?: boolean
  done?: boolean        // checked state for `todo` nodes
}
