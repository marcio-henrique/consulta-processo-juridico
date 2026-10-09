import { screen, waitFor, within } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { HttpResponse, graphql } from 'msw'
import { Route, Routes } from 'react-router-dom'
import { describe, expect, it, vi } from 'vitest'
import { axe } from 'vitest-axe'
import { server } from '../test/msw/server'
import {
  DEMO_NUMBER,
  NOT_IN_DATA_NUMBER,
  NO_SUMMARY_NUMBER,
  SUMMARY_BODY,
  userError,
} from '../test/msw/handlers'
import { renderWithProviders } from '../test/render'
import { LawsuitPage } from './LawsuitPage'

function renderLawsuit(number: string) {
  return renderWithProviders(
    <Routes>
      <Route path="/processos/:number" element={<LawsuitPage />} />
    </Routes>,
    { route: `/processos/${number}` },
  )
}

describe('LawsuitPage', () => {
  it('shows the header, data, cached summary and movements in this order', async () => {
    const { container } = renderLawsuit(DEMO_NUMBER)
    expect(await screen.findByRole('heading', { level: 1, name: /1001399-31\.2023\.8\.26\.0070/ })).toBeInTheDocument()

    const headings = screen.getAllByRole('heading').map((h) => h.textContent)
    expect(headings).toEqual([
      'Processo 1001399-31.2023.8.26.0070',
      'Dados do processo',
      'Resumo do processo',
      'Movimentações',
    ])
    expect(screen.getByText('R$ 10.000,00')).toBeInTheDocument()
    expect(screen.getAllByTestId('summary-paragraph')).toHaveLength(3)
    expect(screen.getAllByRole('row')).toHaveLength(26) // header + first 25
    expect(screen.getByRole('status')).toHaveTextContent('Exibindo 25 de 46 movimentações.')
    expect(document.title).toBe('Processo 1001399-31.2023.8.26.0070 | Consulta de Processo')
    expect(await axe(container)).toHaveNoViolations()
  })

  it('does not call generateSummary when a cached summary exists', async () => {
    const generate = vi.fn()
    server.use(
      graphql.mutation('GenerateSummary', () => {
        generate()
        return HttpResponse.json({ data: { generateSummary: { summary: null, errors: [] } } })
      }),
    )
    renderLawsuit(DEMO_NUMBER)
    await screen.findByText('Dados do processo')
    expect(generate).not.toHaveBeenCalled()
  })

  it('appends the next page with Carregar mais', async () => {
    const user = userEvent.setup()
    renderLawsuit(DEMO_NUMBER)
    await screen.findByText('Dados do processo')
    await user.click(screen.getByRole('button', { name: 'Carregar mais' }))
    await waitFor(() => expect(screen.getAllByRole('row')).toHaveLength(46 + 1))
    expect(screen.getByRole('status')).toHaveTextContent('Exibindo 46 de 46 movimentações.')
    expect(screen.queryByRole('button', { name: 'Carregar mais' })).not.toBeInTheDocument()
  })

  it('shows skeletons while loading, with the rest of the page usable', async () => {
    renderLawsuit(DEMO_NUMBER)
    expect(screen.getByRole('heading', { level: 1 })).toHaveTextContent('Processo 1001399-31.2023.8.26.0070')
    expect(screen.getByText('Carregando processo…')).toBeInTheDocument()
    expect(screen.getByRole('link', { name: 'Nova consulta' })).toBeInTheDocument()
    await screen.findByText('Dados do processo')
  })

  it('shows the not-found state for a valid number that is not in the data', async () => {
    renderLawsuit(NOT_IN_DATA_NUMBER)
    expect(
      await screen.findByRole('heading', { level: 1, name: 'Processo não encontrado na base.' }),
    ).toBeInTheDocument()
    expect(screen.getByText(/Somente processos importados/)).toBeInTheDocument()
    expect(screen.getByRole('link', { name: 'Consultar outro processo' })).toHaveAttribute('href', '/')
    expect(document.title).toBe('Processo não encontrado | Consulta de Processo')
  })

  it('shows the not-found state for an invalid CNJ in the URL', async () => {
    renderLawsuit('123')
    expect(await screen.findByRole('heading', { level: 1, name: 'Processo não encontrado na base.' })).toBeInTheDocument()
  })

  it('shows a generic error with retry on network failure, hiding technical details', async () => {
    const user = userEvent.setup()
    server.use(graphql.query('Lawsuit', () => HttpResponse.error()))
    renderLawsuit(DEMO_NUMBER)
    const alert = await screen.findByRole('alert')
    expect(alert).toHaveTextContent('Não foi possível carregar o processo. Tente novamente.')
    expect(alert).not.toHaveTextContent(/fetch|network|failed/i)

    server.resetHandlers()
    await user.click(screen.getByRole('button', { name: 'Tentar novamente' }))
    expect(await screen.findByText('Dados do processo')).toBeInTheDocument()
  })

  it('shows the generic error when the API answers with a server error status', async () => {
    server.use(graphql.query('Lawsuit', () => HttpResponse.json({ errors: [{ message: 'secret detail' }] })))
    renderLawsuit(DEMO_NUMBER)
    const alert = await screen.findByRole('alert')
    expect(alert).not.toHaveTextContent('secret detail')
  })

  it('shows the canonical number returned by the API for a digits-only URL', async () => {
    renderLawsuit('10013993120238260070')
    expect(await screen.findByRole('heading', { level: 1, name: 'Processo 1001399-31.2023.8.26.0070' })).toBeInTheDocument()
  })

  describe('summary generation', () => {
    it('generates the summary automatically, exactly once, when none is cached', async () => {
      const generate = vi.fn()
      server.use(
        graphql.mutation('GenerateSummary', ({ variables }) => {
          generate(variables)
          return HttpResponse.json({
            data: {
              generateSummary: {
                summary: { id: '11', body: SUMMARY_BODY, generatedAt: '2026-10-09T12:00:00Z' },
                errors: [],
              },
            },
          })
        }),
      )
      renderLawsuit(NO_SUMMARY_NUMBER)
      const live = await screen.findByTestId('summary-live')
      await waitFor(() => expect(within(live).getAllByTestId('summary-paragraph')).toHaveLength(3))
      expect(generate).toHaveBeenCalledTimes(1)
      expect(generate).toHaveBeenCalledWith({ lawsuitNumber: NO_SUMMARY_NUMBER })
    })

    it('shows aria-busy only in the summary while generating', async () => {
      server.use(
        graphql.mutation('GenerateSummary', async () => {
          await new Promise((resolve) => setTimeout(resolve, 100))
          return HttpResponse.json({ data: { generateSummary: { summary: null, errors: [] } } })
        }),
      )
      renderLawsuit(NO_SUMMARY_NUMBER)
      const live = await screen.findByTestId('summary-live')
      expect(live).toHaveAttribute('aria-busy', 'true')
      expect(screen.getByText('Dados do processo')).toBeInTheDocument()
      expect(screen.getAllByRole('row').length).toBeGreaterThan(1)
    })

    it.each(['SUMMARY_UNAVAILABLE', 'RATE_LIMITED'])('shows an error with retry on %s', async (code) => {
      const user = userEvent.setup()
      let calls = 0
      server.use(
        graphql.mutation('GenerateSummary', () => {
          calls += 1
          if (calls === 1) {
            return HttpResponse.json({
              data: { generateSummary: { summary: null, errors: [userError(code, 'x')] } },
            })
          }
          return HttpResponse.json({
            data: {
              generateSummary: {
                summary: { id: '12', body: SUMMARY_BODY, generatedAt: '2026-10-09T12:00:00Z' },
                errors: [],
              },
            },
          })
        }),
      )
      renderLawsuit(NO_SUMMARY_NUMBER)
      expect(await screen.findByText('Não foi possível gerar o resumo agora.')).toBeInTheDocument()
      await user.click(screen.getByRole('button', { name: 'Tentar novamente' }))
      await waitFor(() => expect(screen.getAllByTestId('summary-paragraph')).toHaveLength(3))
      expect(calls).toBe(2)
    })

    it('shows an error with retry when the mutation fails on the network', async () => {
      server.use(graphql.mutation('GenerateSummary', () => HttpResponse.error()))
      renderLawsuit(NO_SUMMARY_NUMBER)
      expect(await screen.findByText('Não foi possível gerar o resumo agora.')).toBeInTheDocument()
    })
  })
})
