// Public API of the `tag` entity for the `note` entity (FSD @x cross-import).
import { tagStore } from '../model/tag.store.svelte'

/**
 * Re-persist the tag links of notes re-created by Undo: deleting a note drops
 * its links server-side, while the local assignment cache still holds them.
 */
export const restoreNoteTags = (noteIds: string[]) => {
  for (const id of noteIds) {
    const tagIds = tagStore.tagIdsForNote(id)
    if (tagIds.length > 0) tagStore.setNoteTags(id, tagIds)
  }
}
