import { Navigate, useSearchParams } from 'react-router-dom'
import { useAuth } from '../auth/AuthProvider'
import { safeNext } from '../auth/safeNext'
import { AuthForm } from '../components/AuthForm'
import { usePageTitle } from '../lib/usePageTitle'

export function SignUpPage() {
  const { status, signUp } = useAuth()
  const [params] = useSearchParams()
  const next = safeNext(params.get('next'))
  usePageTitle('Criar conta')

  if (status === 'authenticated') return <Navigate to={next} replace />

  return (
    <AuthForm
      idPrefix="signup"
      heading="Criar conta"
      submitLabel="Criar conta"
      passwordAutoComplete="new-password"
      passwordHint="A senha deve ter de 10 a 72 caracteres."
      onSubmit={signUp}
      alternative={{
        text: 'Já tenho conta',
        to: next === '/' ? '/login' : `/login?next=${encodeURIComponent(next)}`,
      }}
    />
  )
}
