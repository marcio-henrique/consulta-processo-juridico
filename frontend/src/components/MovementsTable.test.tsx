import { render, screen, within } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { describe, expect, it, vi } from 'vitest'
import { axe } from 'vitest-axe'
import { buildMovements, LONG_CONTENT } from '../test/msw/handlers'
import { MovementsTable } from './MovementsTable'

const movements = buildMovements(5)

function setup(overrides: Partial<React.ComponentProps<typeof MovementsTable>> = {}) {
  const onLoadMore = vi.fn()
  const utils = render(
    <MovementsTable
      movements={movements}
      total={46}
      hasMore={false}
      loadingMore={false}
      onLoadMore={onLoadMore}
      {...overrides}
    />,
  )
  return { onLoadMore, ...utils }
}

describe('MovementsTable', () => {
  it('renders a table with a caption and column headers', () => {
    setup()
    const table = screen.getByRole('table', { name: 'Movimentações do processo' })
    const headers = within(table).getAllByRole('columnheader')
    expect(headers.map((h) => h.textContent)).toEqual(['Data', 'Movimentação'])
    headers.forEach((h) => expect(h).toHaveAttribute('scope', 'col'))
  })

  it('keeps the order given by the API and formats dates as dd/mm/aaaa', () => {
    setup()
    const rows = screen.getAllByRole('row').slice(1) // skip header row
    expect(rows).toHaveLength(5)
    expect(within(rows[0]).getByText('12/06/2024')).toBeInTheDocument()
    expect(within(rows[0]).getByText('Certidão de Publicação Expedida')).toBeInTheDocument()
    expect(within(rows[1]).getByText('11/06/2024')).toBeInTheDocument()
  })

  it('shows the title in bold and the content below it, preserving line breaks', () => {
    setup()
    const title = screen.getByText('Movimentação 4')
    expect(title.tagName).toBe('STRONG')
    const content = screen.getByText(/Conteúdo 4/)
    expect(content.textContent).toBe('Conteúdo 4\nSegunda linha')
    expect(content).toHaveClass('movement__content')
  })

  it('does not render a content block when the court gave no content', () => {
    setup()
    const row = screen.getByText('Movimentação 3').closest('tr')!
    expect(row.querySelector('.movement__content')).toBeNull()
  })

  it('collapses long content behind a Ver mais / Ver menos toggle with aria-expanded', async () => {
    const user = userEvent.setup()
    setup()
    const toggle = screen.getByRole('button', { name: 'Ver mais' })
    expect(toggle).toHaveAttribute('aria-expanded', 'false')
    const content = screen.getByText(LONG_CONTENT)
    expect(content).toHaveClass('movement__content--collapsed')
    expect(toggle).toHaveAttribute('aria-controls', content.id)

    await user.click(toggle)
    expect(screen.getByRole('button', { name: 'Ver menos' })).toHaveAttribute('aria-expanded', 'true')
    expect(content).not.toHaveClass('movement__content--collapsed')

    await user.click(screen.getByRole('button', { name: 'Ver menos' }))
    expect(screen.getByRole('button', { name: 'Ver mais' })).toHaveAttribute('aria-expanded', 'false')
  })

  it('does not offer a toggle for short content', () => {
    setup({ movements: buildMovements(1) })
    expect(screen.queryByRole('button', { name: /Ver/ })).not.toBeInTheDocument()
  })

  it('shows how many movements are displayed in a status region', () => {
    setup()
    expect(screen.getByRole('status')).toHaveTextContent('Exibindo 5 de 46 movimentações.')
  })

  it('offers Carregar mais only when there are more pages', async () => {
    const user = userEvent.setup()
    const { onLoadMore, rerender } = setup({ hasMore: true })
    await user.click(screen.getByRole('button', { name: 'Carregar mais' }))
    expect(onLoadMore).toHaveBeenCalledTimes(1)

    rerender(
      <MovementsTable
        movements={movements}
        total={5}
        hasMore={false}
        loadingMore={false}
        onLoadMore={onLoadMore}
      />,
    )
    expect(screen.queryByRole('button', { name: 'Carregar mais' })).not.toBeInTheDocument()
  })

  it('disables Carregar mais while the next page loads', () => {
    setup({ hasMore: true, loadingMore: true })
    expect(screen.getByRole('button', { name: /Carregando/ })).toBeDisabled()
  })

  it('shows the empty state when there are no movements', () => {
    setup({ movements: [], total: 0 })
    expect(screen.getByText('Nenhuma movimentação registrada.')).toBeInTheDocument()
    expect(screen.queryByRole('table')).not.toBeInTheDocument()
  })

  it('has no accessibility violations', async () => {
    const { container } = setup({ hasMore: true })
    expect(await axe(container)).toHaveNoViolations()
  })
})
