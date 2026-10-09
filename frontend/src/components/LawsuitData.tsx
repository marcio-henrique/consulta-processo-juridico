import type { LawsuitQuery } from '../graphql/generated/graphql'

export type LawsuitNode = NonNullable<LawsuitQuery['lawsuit']['lawsuit']>

type Props = {
  lawsuit: Pick<LawsuitNode, 'forum' | 'court' | 'numberOfAuthors' | 'value'>
}

// Only fields the data provides (no status, class, subject or judge).
export function LawsuitData({ lawsuit }: Props) {
  const rows: Array<[string, string]> = [
    ['Foro', lawsuit.forum],
    ['Vara', lawsuit.court],
    ['Valor da ação', lawsuit.value.formatted],
    ['Número de autores', String(lawsuit.numberOfAuthors)],
  ]

  return (
    <section className="section" aria-labelledby="lawsuit-data-title">
      <h2 id="lawsuit-data-title" className="section__title">
        Dados do processo
      </h2>
      <dl className="data-list">
        {rows.map(([label, value]) => (
          <div className="data-list__row" key={label}>
            <dt>{label}</dt>
            <dd>{value}</dd>
          </div>
        ))}
      </dl>
    </section>
  )
}
