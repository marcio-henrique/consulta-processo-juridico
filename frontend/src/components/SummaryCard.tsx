import { splitParagraphs } from '../lib/format'

export const DISCLAIMER =
  'Resumo gerado por inteligência artificial a partir das movimentações do processo. Não substitui a análise de um advogado.'

type Props = {
  status: 'ready' | 'loading' | 'error'
  body?: string
  onRetry: () => void
}

// The summary is plain text from the LLM: it is only ever rendered as React
// text nodes (never as HTML). Paragraphs are split on blank lines.
export function SummaryCard({ status, body, onRetry }: Props) {
  return (
    <section className="section summary" aria-labelledby="summary-title">
      <h2 id="summary-title" className="section__title">
        Resumo do processo
      </h2>

      <div data-testid="summary-live" aria-live="polite" aria-busy={status === 'loading'}>
        {status === 'ready' && body
          ? splitParagraphs(body).map((paragraph, index) => (
              <p key={index} data-testid="summary-paragraph">
                {paragraph}
              </p>
            ))
          : null}

        {status === 'loading' ? (
          <div>
            <p className="summary__loading">Gerando resumo…</p>
            <div className="skeleton" aria-hidden="true">
              <span className="skeleton__line" />
              <span className="skeleton__line" />
              <span className="skeleton__line skeleton__line--short" />
            </div>
          </div>
        ) : null}

        {status === 'error' ? (
          <div>
            <p className="summary__error">Não foi possível gerar o resumo agora.</p>
            <button type="button" className="button button--secondary" onClick={onRetry}>
              Tentar novamente
            </button>
          </div>
        ) : null}
      </div>

      <p className="summary__disclaimer">{DISCLAIMER}</p>
    </section>
  )
}
