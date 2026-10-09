import { useEffect, useRef, useState } from 'react'
import { Link, Outlet, useLocation, useNavigate } from 'react-router-dom'
import { useAuth } from '../auth/AuthProvider'
import { SkipLink } from './SkipLink'

export const MAIN_ID = 'conteudo'

export function AppShell() {
  const { pathname } = useLocation()
  const navigate = useNavigate()
  const { status, user, signOut } = useAuth()
  const [signingOut, setSigningOut] = useState(false)
  const firstRender = useRef(true)

  // Move focus to the new page's h1 after a route change (WCAG 2.4.3). The
  // first render is skipped so the skip link stays the first tab stop.
  useEffect(() => {
    if (firstRender.current) {
      firstRender.current = false
      return
    }
    const heading = document.querySelector<HTMLElement>(`#${MAIN_ID} h1`)
    heading?.setAttribute('tabindex', '-1')
    heading?.focus()
  }, [pathname])

  async function handleSignOut() {
    setSigningOut(true)
    await signOut()
    setSigningOut(false)
    navigate('/login', { replace: true })
  }

  return (
    <>
      <SkipLink targetId={MAIN_ID} />
      <header className="app-header">
        <div className="app-header__inner">
          <Link to="/" className="app-header__brand">
            Consulta de Processo
          </Link>
          {status === 'authenticated' && user ? (
            <div className="app-header__user">
              <span className="app-header__email">{user.email}</span>
              <button
                type="button"
                className="button button--link"
                disabled={signingOut}
                onClick={() => void handleSignOut()}
              >
                Sair
              </button>
            </div>
          ) : null}
        </div>
      </header>
      <main id={MAIN_ID} className="app-main">
        <Outlet />
      </main>
      <footer className="app-footer">
        <p>Os dados exibidos vêm de uma base importada para este desafio técnico.</p>
      </footer>
    </>
  )
}
