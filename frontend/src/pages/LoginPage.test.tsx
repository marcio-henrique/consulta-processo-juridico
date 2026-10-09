import { screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { HttpResponse, graphql } from 'msw'
import { Route, Routes, useLocation } from 'react-router-dom'
import { describe, expect, it } from 'vitest'
import { axe } from 'vitest-axe'
import { server } from '../test/msw/server'
import { renderWithProviders } from '../test/render'
import { LoginPage } from './LoginPage'

function Where() {
  const { pathname, search } = useLocation()
  return <p data-testid="where">{pathname + search}</p>
}

function renderLogin(route = '/login') {
  server.use(graphql.query('Me', () => HttpResponse.json({ data: { me: null } })))
  return renderWithProviders(
    <Routes>
      <Route path="/login" element={<LoginPage />} />
      <Route path="*" element={<Where />} />
    </Routes>,
    { route },
  )
}

async function fill(user: ReturnType<typeof userEvent.setup>, email: string, password: string) {
  if (email) await user.type(screen.getByLabelText(/^e-mail/i), email)
  if (password) await user.type(screen.getByLabelText(/^senha/i), password)
}

describe('LoginPage', () => {
  it('has an h1, a title, labeled fields with autocomplete and a link to sign up', async () => {
    renderLogin()
    expect(await screen.findByRole('heading', { level: 1, name: 'Entrar' })).toBeInTheDocument()
    expect(document.title).toBe('Entrar | Consulta de Processo')
    const email = screen.getByLabelText(/^e-mail/i)
    const password = screen.getByLabelText(/^senha/i)
    expect(email).toHaveAttribute('autocomplete', 'email')
    expect(email).toHaveAttribute('type', 'email')
    expect(password).toHaveAttribute('autocomplete', 'current-password')
    expect(password).toHaveAttribute('type', 'password')
    expect(screen.getByRole('link', { name: 'Criar conta' })).toHaveAttribute('href', '/cadastro')
  })

  it('keeps next in the sign up link', async () => {
    renderLogin('/login?next=%2Fprocessos%2F1')
    expect(await screen.findByRole('link', { name: 'Criar conta' })).toHaveAttribute(
      'href',
      '/cadastro?next=%2Fprocessos%2F1',
    )
  })

  it('shows field errors, marks fields invalid and focuses the first one when empty', async () => {
    const user = userEvent.setup()
    renderLogin()
    await screen.findByRole('heading', { level: 1 })
    await user.click(screen.getByRole('button', { name: 'Entrar' }))

    const email = screen.getByLabelText(/^e-mail/i)
    expect(email).toHaveFocus()
    expect(email).toHaveAttribute('aria-invalid', 'true')
    expect(email).toHaveAccessibleDescription(/Informe o e-mail\./)
    expect(screen.getByLabelText(/^senha/i)).toHaveAccessibleDescription(/Informe a senha\./)
    expect(screen.getAllByRole('alert')).toHaveLength(2)
  })

  it('shows the server message for wrong credentials, keeps the data and focuses the e-mail', async () => {
    const user = userEvent.setup()
    renderLogin()
    await screen.findByRole('heading', { level: 1 })
    await fill(user, 'ana@example.com', 'wrong-password-1')
    await user.click(screen.getByRole('button', { name: 'Entrar' }))

    expect(await screen.findByRole('alert')).toHaveTextContent('E-mail ou senha inválidos.')
    expect(screen.getByLabelText(/^e-mail/i)).toHaveValue('ana@example.com')
    expect(screen.getByLabelText(/^senha/i)).toHaveValue('wrong-password-1')
    expect(screen.getByLabelText(/^e-mail/i)).toHaveFocus()
    expect(screen.getByLabelText(/^e-mail/i)).toHaveAccessibleDescription(/E-mail ou senha inválidos\./)
  })

  it('shows a generic message when the request fails', async () => {
    const user = userEvent.setup()
    renderLogin()
    server.use(graphql.mutation('SignIn', () => HttpResponse.error()))
    await screen.findByRole('heading', { level: 1 })
    await fill(user, 'ana@example.com', 'a-very-safe-password')
    await user.click(screen.getByRole('button', { name: 'Entrar' }))
    expect(await screen.findByRole('alert')).toHaveTextContent('Não foi possível concluir agora. Tente novamente.')
  })

  it('goes home after a successful sign in', async () => {
    const user = userEvent.setup()
    renderLogin()
    await screen.findByRole('heading', { level: 1 })
    await fill(user, 'ana@example.com', 'a-very-safe-password')
    await user.click(screen.getByRole('button', { name: 'Entrar' }))
    await waitFor(() => expect(screen.getByTestId('where')).toHaveTextContent(/^\/$/))
  })

  it('returns to next after a successful sign in', async () => {
    const user = userEvent.setup()
    renderLogin('/login?next=%2Fprocessos%2F1001399-31.2023.8.26.0070')
    await screen.findByRole('heading', { level: 1 })
    await fill(user, 'ana@example.com', 'a-very-safe-password')
    await user.click(screen.getByRole('button', { name: 'Entrar' }))
    await waitFor(() =>
      expect(screen.getByTestId('where')).toHaveTextContent('/processos/1001399-31.2023.8.26.0070'),
    )
  })

  it('ignores a malicious next', async () => {
    const user = userEvent.setup()
    renderLogin('/login?next=%2F%2Fevil.com')
    await screen.findByRole('heading', { level: 1 })
    await fill(user, 'ana@example.com', 'a-very-safe-password')
    await user.click(screen.getByRole('button', { name: 'Entrar' }))
    await waitFor(() => expect(screen.getByTestId('where')).toHaveTextContent(/^\/$/))
  })

  it('redirects a signed-in visitor away from /login', async () => {
    server.resetHandlers() // Me answers with a signed-in user
    renderWithProviders(
      <Routes>
        <Route path="/login" element={<LoginPage />} />
        <Route path="*" element={<Where />} />
      </Routes>,
      { route: '/login' },
    )
    await waitFor(() => expect(screen.getByTestId('where')).toHaveTextContent(/^\/$/))
  })

  it('allows paste in the password field and has no accessibility violations', async () => {
    const user = userEvent.setup()
    const { container } = renderLogin()
    await screen.findByRole('heading', { level: 1 })
    const password = screen.getByLabelText(/^senha/i)
    await user.click(password)
    await user.paste('pasted-password-123')
    expect(password).toHaveValue('pasted-password-123')
    await user.click(screen.getByRole('button', { name: 'Entrar' }))
    expect(await axe(container)).toHaveNoViolations()
  })
})
