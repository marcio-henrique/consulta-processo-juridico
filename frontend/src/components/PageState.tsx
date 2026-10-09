import { Link } from 'react-router-dom'

type Props =
  | { kind: 'loading' }
  | { kind: 'not-found' }
  | { kind: 'error'; onRetry: () => void }

// Body of the lawsuit page when there is no lawsuit to show. The heading is
// rendered by the page (see LawsuitHeader).
export function PageState(props: Props) {
  if (props.kind === 'loading') {
    return (
      <div className="page-state" aria-busy="true">
        <p className="visually-hidden" role="status">
          Carregando processo…
        </p>
        <div className="skeleton skeleton--block" aria-hidden="true">
          <span className="skeleton__line" />
          <span className="skeleton__line" />
          <span className="skeleton__line skeleton__line--short" />
        </div>
        <div className="skeleton skeleton--block" aria-hidden="true">
          <span className="skeleton__line" />
          <span className="skeleton__line" />
          <span className="skeleton__line" />
          <span className="skeleton__line skeleton__line--short" />
        </div>
      </div>
    )
  }

  if (props.kind === 'not-found') {
    return (
      <div className="page-state">
        <p>Somente processos importados para esta base estão disponíveis para consulta.</p>
        <Link to="/">Consultar outro processo</Link>
      </div>
    )
  }

  return (
    <div className="page-state">
      <p className="alert" role="alert">
        Não foi possível carregar o processo. Tente novamente.
      </p>
      <button type="button" className="button" onClick={props.onRetry}>
        Tentar novamente
      </button>
    </div>
  )
}
