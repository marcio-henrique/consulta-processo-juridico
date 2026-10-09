import { screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { HttpResponse, graphql } from 'msw'
import { Route, Routes, useLocation } from 'react-router-dom'
import { describe, expect, it } from 'vitest'
import { axe } from 'vitest-axe'
import { server } from '../test/msw/server'
import { renderWithProviders } from '../test/render'
import { SignUpPage } from './SignUpPage'

function Where() {
  const { pathname, search } = useLocation()
  return <p data-testid="where">{pathname + search}</p>
}

function renderSignUp(route = '/cadastro') {
  server.use(graphql.query('Me', () => HttpResponse.json({ data: { me: null } })))
  return renderWithProviders(
    <Routes>
      <Route path="/cadastro" element={<SignUpPage />} />
      <Route path="*" element={<Where />} />
    </Routes>,
    { route },
  )
}

async function fill(user: ReturnType<typeof userEvent.setup>, email: string, password: string) {
  if (email) await user.type(screen.getByLabelText(/^e-mail/i), email)
  if (password) await user.type(screen.getByLabelText(/^senha/i), password)
}

describe('SignUpPage', () => {
  it('has an h1, title, labeled fields, password rule hint and a link to sign in', async () => {
    renderSignUp('/cadastro?next=%2Fprocessos%2F1')
    expect(await screen.findByRole('heading', { level: 1, name: 'Criar conta' })).toBeInTheDocument()
    expect(document.title).toBe('Criar conta | Consulta de Processo')
    const password = screen.getByLabelText(/^senha/i)
    expect(password).toHaveAttribute('autocomplete', 'new-password')
    expect(password).toHaveAccessibleDescription(/de 10 a 72 caracteres/i)
    expect(screen.getByLabelText(/^e-mail/i)).toHaveAttribute('autocomplete', 'email')
    expect(screen.getByRole('link', { name: 'Já tenho conta' })).toHaveAttribute('href', '/login?next=%2Fprocessos%2F1')
  })

  it('shows the server field errors next to the fields and focuses the first invalid one', async () => {
    const user = userEvent.setup()
    renderSignUp()
    await screen.findByRole('heading', { level: 1 })
    await fill(user, 'taken@example.com', 'short')
    await user.click(screen.getByRole('button', { name: 'Criar conta' }))

    const email = screen.getByLabelText(/^e-mail/i)
    await waitFor(() => expect(email).toHaveFocus())
    expect(email).toHaveAttribute('aria-invalid', 'true')
    expect(email).toHaveAccessibleDescription(/Este e-mail já está em uso\./)
    expect(screen.getByLabelText(/^senha/i)).toHaveAccessibleDescription(/A senha deve ter de 10 a 72 caracteres\./)
    expect(screen.getByLabelText(/^e-mail/i)).toHaveValue('taken@example.com') // data preserved
  })

  it('asks for the missing fields without calling the server', async () => {
    const user = userEvent.setup()
    renderSignUp()
    await screen.findByRole('heading', { level: 1 })
    await user.click(screen.getByRole('button', { name: 'Criar conta' }))
    expect(screen.getByLabelText(/^e-mail/i)).toHaveAccessibleDescription(/Informe o e-mail\./)
    expect(screen.getByLabelText(/^senha/i)).toHaveAccessibleDescription(/Informe a senha\./)
  })

  it('goes to next after creating the account', async () => {
    const user = userEvent.setup()
    renderSignUp('/cadastro?next=%2Fprocessos%2F1001399-31.2023.8.26.0070')
    await screen.findByRole('heading', { level: 1 })
    await fill(user, 'new@example.com', 'a-very-safe-password')
    await user.click(screen.getByRole('button', { name: 'Criar conta' }))
    await waitFor(() =>
      expect(screen.getByTestId('where')).toHaveTextContent('/processos/1001399-31.2023.8.26.0070'),
    )
  })

  it('shows a generic message when the request fails', async () => {
    const user = userEvent.setup()
    renderSignUp()
    server.use(graphql.mutation('SignUp', () => HttpResponse.error()))
    await screen.findByRole('heading', { level: 1 })
    await fill(user, 'new@example.com', 'a-very-safe-password')
    await user.click(screen.getByRole('button', { name: 'Criar conta' }))
    expect(await screen.findByRole('alert')).toHaveTextContent('Não foi possível concluir agora. Tente novamente.')
  })

  it('has no accessibility violations, with and without errors', async () => {
    const user = userEvent.setup()
    const { container } = renderSignUp()
    await screen.findByRole('heading', { level: 1 })
    expect(await axe(container)).toHaveNoViolations()
    await user.click(screen.getByRole('button', { name: 'Criar conta' }))
    expect(await axe(container)).toHaveNoViolations()
  })
})
