import { render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { axe } from 'vitest-axe'
import { describe, expect, it, vi } from 'vitest'
import { CnjSearchForm } from './CnjSearchForm'

const VALID = '1001399-31.2023.8.26.0070'
const VALID_DIGITS = '10013993120238260070'

function setup() {
  const onSubmit = vi.fn()
  const user = userEvent.setup()
  const utils = render(<CnjSearchForm onSubmit={onSubmit} />)
  const input = screen.getByLabelText(/número do processo/i)
  return { onSubmit, user, input, ...utils }
}

describe('CnjSearchForm', () => {
  it('has a labeled field and a Consultar button', () => {
    setup()
    expect(screen.getByRole('textbox', { name: /número do processo/i })).toBeInTheDocument()
    expect(screen.getByRole('button', { name: 'Consultar' })).toBeInTheDocument()
  })

  it('applies the CNJ mask while typing', async () => {
    const { user, input } = setup()
    await user.type(input, VALID_DIGITS)
    expect(input).toHaveValue(VALID)
  })

  it('accepts pasted formatted text and digits-only text', async () => {
    const { user, input } = setup()
    await user.click(input)
    await user.paste(VALID)
    expect(input).toHaveValue(VALID)
    await user.clear(input)
    await user.paste(VALID_DIGITS)
    expect(input).toHaveValue(VALID)
  })

  it('shows an alert and keeps focus on the field when empty', async () => {
    const { user, input, onSubmit } = setup()
    await user.click(screen.getByRole('button', { name: 'Consultar' }))
    expect(screen.getByRole('alert')).toHaveTextContent('Informe o número do processo.')
    expect(input).toHaveFocus()
    expect(input).toHaveAttribute('aria-invalid', 'true')
    expect(input).toHaveAccessibleDescription(/Informe o número do processo\./)
    expect(onSubmit).not.toHaveBeenCalled()
  })

  it('shows an alert for an invalid number and does not submit', async () => {
    const { user, input, onSubmit } = setup()
    await user.type(input, '1001399-31.2023.8.26.0071')
    await user.click(screen.getByRole('button', { name: 'Consultar' }))
    expect(screen.getByRole('alert')).toHaveTextContent(
      'Número de processo inválido. Confira os dígitos.',
    )
    expect(input).toHaveFocus()
    expect(input).toHaveValue('1001399-31.2023.8.26.0071') // data is preserved
    expect(onSubmit).not.toHaveBeenCalled()
  })

  it('submits the canonical number for a valid entry', async () => {
    const { user, input, onSubmit } = setup()
    await user.type(input, VALID_DIGITS)
    await user.click(screen.getByRole('button', { name: 'Consultar' }))
    expect(onSubmit).toHaveBeenCalledWith(VALID)
  })

  it('submits with Enter', async () => {
    const { user, input, onSubmit } = setup()
    await user.type(input, `${VALID}{Enter}`)
    expect(onSubmit).toHaveBeenCalledWith(VALID)
  })

  it('clears the error once the user edits the field', async () => {
    const { user, input } = setup()
    await user.click(screen.getByRole('button', { name: 'Consultar' }))
    expect(screen.getByRole('alert')).toBeInTheDocument()
    await user.type(input, '1')
    expect(screen.queryByRole('alert')).not.toBeInTheDocument()
  })

  it('has no accessibility violations, with and without an error', async () => {
    const { user, container } = setup()
    expect(await axe(container)).toHaveNoViolations()
    await user.click(screen.getByRole('button', { name: 'Consultar' }))
    expect(await axe(container)).toHaveNoViolations()
  })
})
