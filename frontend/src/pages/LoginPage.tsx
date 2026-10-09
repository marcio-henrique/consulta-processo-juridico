import { Navigate, useSearchParams } from 'react-router-dom'
import { useAuth } from '../auth/AuthProvider'
import { safeNext } from '../auth/safeNext'
import { AuthForm } from '../components/AuthForm'
import { usePageTitle } from '../lib/usePageTitle'

export function LoginPage() {
  const { status, signIn } = useAuth()
  const [params] = useSearchParams()
  const next = safeNext(params.get('next'))
  usePageTitle('Entrar')

  // Signed-in visitors never see the form (requirement 6.4); right after a
  // successful sign in this same redirect sends the user to `next`.
  if (status === 'authenticated') return <Navigate to={next} replace />

  return (
    <AuthForm
      idPrefix="login"
      heading="Entrar"
      submitLabel="Entrar"
      passwordAutoComplete="current-password"
      onSubmit={signIn}
      alternative={{
        text: 'Criar conta',
        to: next === '/' ? '/cadastro' : `/cadastro?next=${encodeURIComponent(next)}`,
      }}
    />
  )
}
