import { Navigate, Outlet, useLocation } from 'react-router-dom'
import { useAuth } from './AuthProvider'
import { loginPath } from './safeNext'

// Layout route for protected pages (spec 06 requirement 6.3). The server
// guard is the real protection; this only avoids showing pages that would
// fail with UNAUTHENTICATED.
export function RequireAuth() {
  const { status, signedOut } = useAuth()
  const location = useLocation()

  if (status === 'loading') {
    return (
      <p role="status" className="auth-loading">
        Carregando…
      </p>
    )
  }

  if (status === 'anonymous') {
    // After an explicit sign out the user goes to a clean /login.
    const target = signedOut ? '/login' : loginPath(location.pathname + location.search)
    return <Navigate to={target} replace />
  }

  return <Outlet />
}
