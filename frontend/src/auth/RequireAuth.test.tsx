import { screen } from '@testing-library/react'
import { HttpResponse, graphql } from 'msw'
import { Route, Routes, useLocation } from 'react-router-dom'
import { describe, expect, it } from 'vitest'
import { server } from '../test/msw/server'
import { renderWithProviders } from '../test/render'
import { RequireAuth } from './RequireAuth'

function Login() {
  const { pathname, search } = useLocation()
  return <p data-testid="login">{pathname + search}</p>
}

function renderGuarded(route: string) {
  return renderWithProviders(
    <Routes>
      <Route path="/login" element={<Login />} />
      <Route element={<RequireAuth />}>
        <Route path="/" element={<p>Home protegida</p>} />
        <Route path="/processos/:number" element={<p>Processo protegido</p>} />
      </Route>
    </Routes>,
    { route },
  )
}

const anonymous = () => server.use(graphql.query('Me', () => HttpResponse.json({ data: { me: null } })))

describe('RequireAuth', () => {
  it('shows a status message while the auth state is loading', () => {
    renderGuarded('/')
    expect(screen.getByRole('status')).toHaveTextContent('Carregando…')
    expect(screen.queryByText('Home protegida')).not.toBeInTheDocument()
  })

  it('renders the protected route for a signed-in user', async () => {
    renderGuarded('/')
    expect(await screen.findByText('Home protegida')).toBeInTheDocument()
  })

  it('redirects anonymous users to /login with the path as next', async () => {
    anonymous()
    renderGuarded('/processos/1001399-31.2023.8.26.0070?x=1')
    expect(await screen.findByTestId('login')).toHaveTextContent(
      '/login?next=%2Fprocessos%2F1001399-31.2023.8.26.0070%3Fx%3D1',
    )
  })

  it('redirects the home page to a plain /login', async () => {
    anonymous()
    renderGuarded('/')
    expect(await screen.findByTestId('login')).toHaveTextContent(/^\/login$/)
  })
})
