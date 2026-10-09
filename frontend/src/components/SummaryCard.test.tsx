import { render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { describe, expect, it, vi } from 'vitest'
import { axe } from 'vitest-axe'
import { SUMMARY_BODY } from '../test/msw/handlers'
import { DISCLAIMER, SummaryCard } from './SummaryCard'

describe('SummaryCard', () => {
  it('shows the title, the paragraphs and the disclaimer when ready', () => {
    render(<SummaryCard status="ready" body={SUMMARY_BODY} onRetry={vi.fn()} />)
    expect(screen.getByRole('heading', { level: 2, name: 'Resumo do processo' })).toBeInTheDocument()
    const paragraphs = screen.getAllByTestId('summary-paragraph')
    expect(paragraphs).toHaveLength(3)
    expect(paragraphs[0]).toHaveTextContent(/^O processo 1001399/)
    expect(screen.getByText(DISCLAIMER)).toBeInTheDocument()
    expect(DISCLAIMER).toBe(
      'Resumo gerado por inteligência artificial a partir das movimentações do processo. Não substitui a análise de um advogado.',
    )
  })

  it('exposes the content inside a polite live region', () => {
    render(<SummaryCard status="ready" body={SUMMARY_BODY} onRetry={vi.fn()} />)
    const region = screen.getByTestId('summary-live')
    expect(region).toHaveAttribute('aria-live', 'polite')
    expect(region).toHaveTextContent('O processo 1001399')
  })

  it('renders a busy skeleton while loading', () => {
    render(<SummaryCard status="loading" onRetry={vi.fn()} />)
    expect(screen.getByTestId('summary-live')).toHaveAttribute('aria-busy', 'true')
    expect(screen.getByText('Gerando resumo…')).toBeInTheDocument()
    expect(screen.queryByTestId('summary-paragraph')).not.toBeInTheDocument()
  })

  it('shows the unavailable message with a retry button on error', async () => {
    const user = userEvent.setup()
    const onRetry = vi.fn()
    render(<SummaryCard status="error" onRetry={onRetry} />)
    expect(screen.getByText('Não foi possível gerar o resumo agora.')).toBeInTheDocument()
    await user.click(screen.getByRole('button', { name: 'Tentar novamente' }))
    expect(onRetry).toHaveBeenCalledTimes(1)
  })

  it('renders the body as text, never as HTML', () => {
    const hostile = '<img src=x onerror="alert(1)">\n\n<script>alert(2)</script>'
    const { container } = render(<SummaryCard status="ready" body={hostile} onRetry={vi.fn()} />)
    expect(container.querySelector('img')).toBeNull()
    expect(container.querySelector('script')).toBeNull()
    expect(screen.getByText('<img src=x onerror="alert(1)">')).toBeInTheDocument()
  })

  it.each(['ready', 'loading', 'error'] as const)('has no accessibility violations (%s)', async (status) => {
    const { container } = render(<SummaryCard status={status} body={SUMMARY_BODY} onRetry={vi.fn()} />)
    expect(await axe(container)).toHaveNoViolations()
  })
})
