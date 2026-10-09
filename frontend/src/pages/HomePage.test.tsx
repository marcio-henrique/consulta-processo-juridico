import { screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { Route, Routes, useLocation } from 'react-router-dom'
import { describe, expect, it } from 'vitest'
import { renderWithProviders } from '../test/render'
import { HomePage } from './HomePage'

function Where() {
  return <p data-testid="where">{useLocation().pathname}</p>
}

function renderHome() {
  return renderWithProviders(
    <Routes>
      <Route path="/" element={<HomePage />} />
      <Route path="/processos/:number" element={<Where />} />
    </Routes>,
  )
}

describe('HomePage', () => {
  it('shows the h1, the search field and the title', () => {
    renderHome()
    expect(screen.getByRole('heading', { level: 1, name: 'Consulta de processo' })).toBeInTheDocument()
    expect(screen.getByRole('button', { name: 'Consultar' })).toBeInTheDocument()
    expect(document.title).toBe('Consulta de processo | Consulta de Processo')
  })

  it('navigates to the canonical lawsuit URL on a valid submit', async () => {
    const user = userEvent.setup()
    renderHome()
    await user.type(screen.getByLabelText(/número do processo/i), '10013993120238260070{Enter}')
    expect(screen.getByTestId('where')).toHaveTextContent('/processos/1001399-31.2023.8.26.0070')
  })

  it('does not navigate when the number is invalid', async () => {
    const user = userEvent.setup()
    renderHome()
    await user.type(screen.getByLabelText(/número do processo/i), '123{Enter}')
    expect(screen.queryByTestId('where')).not.toBeInTheDocument()
    expect(screen.getByRole('alert')).toBeInTheDocument()
  })
})
