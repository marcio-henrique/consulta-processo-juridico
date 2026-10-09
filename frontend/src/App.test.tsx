import { screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { HttpResponse, graphql } from 'msw'
import { describe, expect, it } from 'vitest'
import { axe } from 'vitest-axe'
import App from './App'
import { server } from './test/msw/server'
import { renderWithProviders } from './test/render'

const anonymous = () => server.use(graphql.query('Me', () => HttpResponse.json({ data: { me: null } })))

describe('App', () => {
  it('renders the landmarks and the skip link as the first focusable element', async () => {
    const user = userEvent.setup()
    renderWithProviders(<App />)
    await screen.findByRole('heading', { level: 1, name: 'Consulta de processo' })
    expect(screen.getByRole('banner')).toBeInTheDocument()
    expect(screen.getByRole('main')).toHaveAttribute('id', 'conteudo')
    expect(screen.getByRole('contentinfo')).toBeInTheDocument()
    await user.tab()
    expect(screen.getByRole('link', { name: 'Ir para o conteúdo' })).toHaveFocus()
  })

  it('has exactly one h1 on the home page and no accessibility violations', async () => {
    const { container } = renderWithProviders(<App />)
    await screen.findByRole('heading', { level: 1, name: 'Consulta de processo' })
    expect(screen.getAllByRole('heading', { level: 1 })).toHaveLength(1)
    expect(await axe(container)).toHaveNoViolations()
  })

  it('moves focus to the new page h1 after navigating', async () => {
    const user = userEvent.setup()
    renderWithProviders(<App />)
    await user.type(await screen.findByLabelText(/número do processo/i), '10013993120238260070{Enter}')
    const heading = await screen.findByRole('heading', { level: 1, name: /1001399-31/ })
    await waitFor(() => expect(heading).toHaveFocus())
    await screen.findByText('Dados do processo')
    expect(heading).toHaveFocus()
  })

  it('shows a not-found page for unknown routes', async () => {
    renderWithProviders(<App />, { route: '/nao-existe' })
    expect(await screen.findByRole('heading', { level: 1, name: 'Página não encontrada' })).toBeInTheDocument()
  })

  describe('authentication', () => {
    it('redirects an anonymous visitor of a protected page to /login?next=', async () => {
      anonymous()
      renderWithProviders(<App />, { route: '/processos/1001399-31.2023.8.26.0070' })
      expect(await screen.findByRole('heading', { level: 1, name: 'Entrar' })).toBeInTheDocument()
      expect(screen.getByRole('link', { name: 'Criar conta' })).toHaveAttribute(
        'href',
        '/cadastro?next=%2Fprocessos%2F1001399-31.2023.8.26.0070',
      )
    })

    it('signs in, lands on next and shows the user menu', async () => {
      anonymous()
      const user = userEvent.setup()
      renderWithProviders(<App />, { route: '/processos/1001399-31.2023.8.26.0070' })
      await user.type(await screen.findByLabelText(/^e-mail/i), 'ana@example.com')
      await user.type(screen.getByLabelText(/^senha/i), 'a-very-safe-password')
      await user.click(screen.getByRole('button', { name: 'Entrar' }))

      expect(await screen.findByRole('heading', { level: 1, name: /1001399-31/ })).toBeInTheDocument()
      expect(screen.getByText('ana@example.com')).toBeInTheDocument()
      expect(screen.getByRole('button', { name: 'Sair' })).toBeInTheDocument()
    })

    it('does not show the user menu to anonymous visitors', async () => {
      anonymous()
      renderWithProviders(<App />, { route: '/login' })
      await screen.findByRole('heading', { level: 1, name: 'Entrar' })
      expect(screen.queryByRole('button', { name: 'Sair' })).not.toBeInTheDocument()
    })

    it('shows the email and signs out: clears the cache and goes to a clean /login', async () => {
      const user = userEvent.setup()
      const { client } = renderWithProviders(<App />)
      expect(await screen.findByText('ana@example.com')).toBeInTheDocument()
      // Put something in the cache that must not survive the sign out.
      await user.type(screen.getByLabelText(/número do processo/i), '10013993120238260070{Enter}')
      await screen.findByText('Dados do processo')
      expect(JSON.stringify(client.cache.extract())).toContain('Foro de Batatais')

      anonymous()
      await user.click(screen.getByRole('button', { name: 'Sair' }))

      expect(await screen.findByRole('heading', { level: 1, name: 'Entrar' })).toBeInTheDocument()
      expect(screen.queryByText('ana@example.com')).not.toBeInTheDocument()
      expect(JSON.stringify(client.cache.extract())).not.toContain('Foro de Batatais')
      expect(screen.getByRole('link', { name: 'Criar conta' })).toHaveAttribute('href', '/cadastro')
    })

    it('redirects to /login?next=<current path> when a request reports UNAUTHENTICATED', async () => {
      const user = userEvent.setup()
      server.use(
        graphql.query('Lawsuit', () =>
          HttpResponse.json({
            data: { lawsuit: { lawsuit: null, errors: [{ code: 'UNAUTHENTICATED', message: 'Faça login para continuar.', field: null }] } },
          }),
        ),
      )
      renderWithProviders(<App />)
      await user.type(await screen.findByLabelText(/número do processo/i), '10013993120238260070{Enter}')

      expect(await screen.findByRole('heading', { level: 1, name: 'Entrar' })).toBeInTheDocument()
      expect(screen.getByRole('link', { name: 'Criar conta' })).toHaveAttribute(
        'href',
        '/cadastro?next=%2Fprocessos%2F1001399-31.2023.8.26.0070',
      )
    })
  })
})
