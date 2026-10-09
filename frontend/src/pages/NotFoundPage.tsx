import { Link } from 'react-router-dom'
import { usePageTitle } from '../lib/usePageTitle'

export function NotFoundPage() {
  usePageTitle('Página não encontrada')
  return (
    <section>
      <h1>Página não encontrada</h1>
      <p>O endereço acessado não existe.</p>
      <Link to="/">Ir para a consulta de processo</Link>
    </section>
  )
}
