import { useEffect, useRef } from 'react'
import { MovementRow } from './MovementRow'
import type { MovementItem } from './MovementRow'

type Props = {
  movements: readonly MovementItem[]
  total: number
  hasMore: boolean
  loadingMore: boolean
  onLoadMore: () => void
}

export function MovementsTable({ movements, total, hasMore, loadingMore, onLoadMore }: Props) {
  const statusRef = useRef<HTMLParagraphElement>(null)
  const hadMore = useRef(hasMore)

  // When "Carregar mais" disappears after the last page, move focus to the
  // status text so keyboard users do not lose their place (WCAG 2.4.3).
  useEffect(() => {
    if (hadMore.current && !hasMore) statusRef.current?.focus()
    hadMore.current = hasMore
  }, [hasMore])

  return (
    <section className="section" aria-labelledby="movements-title">
      <h2 id="movements-title" className="section__title">
        Movimentações
      </h2>

      {movements.length === 0 ? (
        <p>Nenhuma movimentação registrada.</p>
      ) : (
        <>
          <div className="table-scroll">
            <table className="movements">
              <caption className="visually-hidden">Movimentações do processo</caption>
              <thead>
                <tr>
                  <th scope="col">Data</th>
                  <th scope="col">Movimentação</th>
                </tr>
              </thead>
              <tbody>
                {movements.map((movement) => (
                  <MovementRow key={movement.id} movement={movement} />
                ))}
              </tbody>
            </table>
          </div>
          <p ref={statusRef} className="movements__status" role="status" tabIndex={-1}>
            {`Exibindo ${movements.length} de ${total} movimentações.`}
          </p>
          {hasMore ? (
            <button type="button" className="button button--secondary" disabled={loadingMore} onClick={onLoadMore}>
              {loadingMore ? 'Carregando…' : 'Carregar mais'}
            </button>
          ) : null}
        </>
      )}
    </section>
  )
}
