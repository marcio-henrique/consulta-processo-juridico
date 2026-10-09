import { useNavigate } from 'react-router-dom'
import { CnjSearchForm } from '../components/CnjSearchForm'
import { usePageTitle } from '../lib/usePageTitle'

export function HomePage() {
  const navigate = useNavigate()
  usePageTitle('Consulta de processo')

  return (
    <section className="home" aria-labelledby="home-title">
      <h1 id="home-title">Consulta de processo</h1>
      <CnjSearchForm onSubmit={(number) => navigate(`/processos/${number}`)} />
    </section>
  )
}
