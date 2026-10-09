import { render, screen } from '@testing-library/react'
import { describe, expect, it } from 'vitest'
import { axe } from 'vitest-axe'
import { lawsuitPayload, DEMO_NUMBER } from '../test/msw/handlers'
import { LawsuitData } from './LawsuitData'

describe('LawsuitData', () => {
  const lawsuit = lawsuitPayload(DEMO_NUMBER, {})!

  it('shows forum, court, value and number of authors, with the API currency', () => {
    render(<LawsuitData lawsuit={lawsuit} />)
    expect(screen.getByRole('heading', { level: 2, name: 'Dados do processo' })).toBeInTheDocument()
    const terms = screen.getAllByRole('term').map((node) => node.textContent)
    expect(terms).toEqual(['Foro', 'Vara', 'Valor da ação', 'Número de autores'])
    expect(screen.getByText('Foro de Batatais')).toBeInTheDocument()
    expect(screen.getByText('2ª Vara Cível')).toBeInTheDocument()
    expect(screen.getByText('R$ 10.000,00')).toBeInTheDocument()
    expect(screen.getByText('1')).toBeInTheDocument()
  })

  it('does not show fields the data does not provide', () => {
    render(<LawsuitData lawsuit={lawsuit} />)
    for (const absent of [/situação/i, /classe/i, /assunto/i, /juiz/i]) {
      expect(screen.queryByText(absent)).not.toBeInTheDocument()
    }
  })

  it('has no accessibility violations', async () => {
    const { container } = render(<LawsuitData lawsuit={lawsuit} />)
    expect(await axe(container)).toHaveNoViolations()
  })
})
