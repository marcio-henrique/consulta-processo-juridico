import { screen } from '@testing-library/react'
import { MemoryRouter } from 'react-router-dom'
import { render } from '@testing-library/react'
import { describe, expect, it } from 'vitest'
import { LawsuitHeader } from './LawsuitHeader'

describe('LawsuitHeader', () => {
  it('shows the number as the page h1 and a link back to the home page', () => {
    render(
      <MemoryRouter>
        <LawsuitHeader number="1001399-31.2023.8.26.0070" />
      </MemoryRouter>,
    )
    expect(
      screen.getByRole('heading', { level: 1, name: /1001399-31\.2023\.8\.26\.0070/ }),
    ).toBeInTheDocument()
    expect(screen.getByRole('link', { name: 'Nova consulta' })).toHaveAttribute('href', '/')
  })
})
