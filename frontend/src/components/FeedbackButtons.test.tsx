import { screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { HttpResponse, delay, graphql } from 'msw'
import { Route, Routes } from 'react-router-dom'
import { describe, expect, it, vi } from 'vitest'
import { axe } from 'vitest-axe'
import { LawsuitPage } from '../pages/LawsuitPage'
import { DEMO_NUMBER, lawsuitPayload, userError } from '../test/msw/handlers'
import { server } from '../test/msw/server'
import { renderWithProviders } from '../test/render'

// The vote lives in the Apollo cache, so the buttons are tested through the
// page that feeds them (query -> cache -> props), with MSW as the API.
function renderLawsuit() {
  return renderWithProviders(
    <Routes>
      <Route path="/processos/:number" element={<LawsuitPage />} />
    </Routes>,
    { route: `/processos/${DEMO_NUMBER}` },
  )
}

function serveVote(myFeedback: boolean | null) {
  server.use(
    graphql.query('Lawsuit', () => {
      const lawsuit = lawsuitPayload(DEMO_NUMBER, { first: 25 })!
      return HttpResponse.json({
        data: {
          lawsuit: {
            __typename: 'LawsuitPayload',
            errors: [],
            lawsuit: { ...lawsuit, latestSummary: { ...lawsuit.latestSummary!, myFeedback } },
          },
        },
      })
    }),
  )
}

const useful = () => screen.getByRole('button', { name: /^(✓ )?Útil$/ })
const notUseful = () => screen.getByRole('button', { name: /Não foi útil/ })

describe('FeedbackButtons', () => {
  it('shows the question and both buttons for a ready summary, unpressed when there is no vote', async () => {
    renderLawsuit()
    expect(await screen.findByText('Este resumo foi útil?')).toBeInTheDocument()
    expect(screen.getByRole('group', { name: 'Este resumo foi útil?' })).toBeInTheDocument()
    expect(useful()).toHaveAttribute('aria-pressed', 'false')
    expect(notUseful()).toHaveAttribute('aria-pressed', 'false')
  })

  it.each([
    [true, 'true', 'false'],
    [false, 'false', 'true'],
  ])('reflects myFeedback=%s on load', async (vote, usefulPressed, notUsefulPressed) => {
    serveVote(vote)
    renderLawsuit()
    await screen.findByText('Este resumo foi útil?')
    expect(useful()).toHaveAttribute('aria-pressed', usefulPressed)
    expect(notUseful()).toHaveAttribute('aria-pressed', notUsefulPressed)
  })

  it('sends the vote, presses the button and announces the thanks in a polite live region', async () => {
    const user = userEvent.setup()
    const rate = vi.fn()
    server.use(
      graphql.mutation('RateSummary', ({ variables }) => {
        rate(variables)
        return HttpResponse.json({
          data: {
            rateSummary: {
              __typename: 'RateSummaryPayload',
              feedback: {
                __typename: 'SummaryFeedback',
                summaryId: variables.summaryId,
                helpful: variables.helpful,
              },
              errors: [],
            },
          },
        })
      }),
    )
    renderLawsuit()
    await screen.findByText('Este resumo foi útil?')
    await user.click(useful())
    expect(await screen.findByText('Obrigado pelo feedback.')).toBeInTheDocument()
    expect(rate).toHaveBeenCalledWith({ summaryId: '10', helpful: true })
    expect(screen.getByText('Obrigado pelo feedback.')).toHaveAttribute('aria-live', 'polite')
    expect(useful()).toHaveAttribute('aria-pressed', 'true')
    expect(notUseful()).toHaveAttribute('aria-pressed', 'false')
  })

  it('updates optimistically, before the server answers', async () => {
    const user = userEvent.setup()
    server.use(
      graphql.mutation('RateSummary', async () => {
        await delay('infinite')
        return HttpResponse.json({ data: null })
      }),
    )
    renderLawsuit()
    await screen.findByText('Este resumo foi útil?')
    await user.click(notUseful())
    await waitFor(() => expect(notUseful()).toHaveAttribute('aria-pressed', 'true'))
    expect(screen.queryByText('Obrigado pelo feedback.')).not.toBeInTheDocument()
  })

  it('changes the vote from one button to the other', async () => {
    const user = userEvent.setup()
    serveVote(true)
    renderLawsuit()
    await screen.findByText('Este resumo foi útil?')
    await user.click(notUseful())
    await screen.findByText('Obrigado pelo feedback.')
    expect(notUseful()).toHaveAttribute('aria-pressed', 'true')
    expect(useful()).toHaveAttribute('aria-pressed', 'false')
  })

  it('reverts the optimistic vote and shows the failure message when the request fails', async () => {
    const user = userEvent.setup()
    serveVote(true)
    server.use(graphql.mutation('RateSummary', () => HttpResponse.error()))
    renderLawsuit()
    await screen.findByText('Este resumo foi útil?')
    await user.click(notUseful())
    expect(await screen.findByText('Não foi possível registrar seu voto.')).toBeInTheDocument()
    expect(useful()).toHaveAttribute('aria-pressed', 'true')
    expect(notUseful()).toHaveAttribute('aria-pressed', 'false')
    expect(screen.queryByText('Obrigado pelo feedback.')).not.toBeInTheDocument()
  })

  it('treats a UserError in the payload as a failure and keeps the previous state', async () => {
    const user = userEvent.setup()
    server.use(
      graphql.mutation('RateSummary', () =>
        HttpResponse.json({
          data: {
            rateSummary: {
              __typename: 'RateSummaryPayload',
              feedback: null,
              errors: [userError('NOT_FOUND', 'Processo não encontrado na base.')],
            },
          },
        }),
      ),
    )
    renderLawsuit()
    await screen.findByText('Este resumo foi útil?')
    await user.click(useful())
    expect(await screen.findByText('Não foi possível registrar seu voto.')).toBeInTheDocument()
    expect(useful()).toHaveAttribute('aria-pressed', 'false')
  })

  it('keeps the vote and shows no error when the active button is clicked again', async () => {
    const user = userEvent.setup()
    const rate = vi.fn()
    serveVote(true)
    server.use(
      graphql.mutation('RateSummary', () => {
        rate()
        return HttpResponse.error()
      }),
    )
    renderLawsuit()
    await screen.findByText('Este resumo foi útil?')
    await user.click(useful())
    expect(useful()).toHaveAttribute('aria-pressed', 'true')
    expect(rate).not.toHaveBeenCalled()
    expect(screen.queryByText('Não foi possível registrar seu voto.')).not.toBeInTheDocument()
  })

  it('has no accessibility violations with a vote', async () => {
    serveVote(false)
    const { container } = renderLawsuit()
    await screen.findByText('Este resumo foi útil?')
    expect(await axe(container)).toHaveNoViolations()
  })
})
