import { useState } from 'react'
import { formatDate } from '../lib/format'

export type MovementItem = {
  id: string
  date: string
  title: string
  content: string | null
}

export const COLLAPSE_THRESHOLD = 300

// Title in bold, content below in smaller muted text (line breaks preserved).
// Long content is collapsed visually; the full text stays in the DOM.
export function MovementRow({ movement }: { movement: MovementItem }) {
  const [expanded, setExpanded] = useState(false)
  const contentId = `movement-content-${movement.id}`
  const titleId = `movement-title-${movement.id}`
  const content = movement.content?.trim() ? movement.content : null
  const collapsible = content !== null && content.length > COLLAPSE_THRESHOLD

  return (
    <tr>
      <td className="movements__date">{formatDate(movement.date)}</td>
      <td className="movements__body">
        <strong id={titleId} className="movement__title">
          {movement.title}
        </strong>
        {content ? (
          <p
            id={contentId}
            className={
              collapsible && !expanded
                ? 'movement__content movement__content--collapsed'
                : 'movement__content'
            }
          >
            {content}
          </p>
        ) : null}
        {collapsible ? (
          <button
            type="button"
            className="button button--link"
            aria-expanded={expanded}
            aria-controls={contentId}
            aria-describedby={titleId}
            onClick={() => setExpanded((value) => !value)}
          >
            {expanded ? 'Ver menos' : 'Ver mais'}
          </button>
        ) : null}
      </td>
    </tr>
  )
}
