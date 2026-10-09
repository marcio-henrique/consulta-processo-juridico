import { useRef, useState } from 'react'
import type { FormEvent } from 'react'
import { digitsOnly, formatCnj, isValidCnj, maskCnj } from '../lib/cnj'
import { TextField } from './TextField'

type Props = {
  onSubmit: (canonicalNumber: string) => void
}

export const EMPTY_MESSAGE = 'Informe o número do processo.'
export const INVALID_MESSAGE = 'Número de processo inválido. Confira os dígitos.'

// Client validation is only fast feedback; the server stays authoritative.
export function CnjSearchForm({ onSubmit }: Props) {
  const [value, setValue] = useState('')
  const [error, setError] = useState<string | null>(null)
  const inputRef = useRef<HTMLInputElement>(null)

  function handleSubmit(event: FormEvent) {
    event.preventDefault()
    const digits = digitsOnly(value)
    const problem = digits === '' ? EMPTY_MESSAGE : isValidCnj(digits) ? null : INVALID_MESSAGE
    setError(problem)
    if (problem) {
      inputRef.current?.focus()
      return
    }
    onSubmit(formatCnj(digits))
  }

  return (
    <form className="search-form" onSubmit={handleSubmit} noValidate>
      <TextField
        id="cnj-number"
        name="number"
        label="Número do processo"
        hint="Exemplo: 1001399-31.2023.8.26.0070"
        autoComplete="off"
        inputMode="numeric"
        value={value}
        error={error}
        inputRef={inputRef}
        onChange={(event) => {
          setValue(maskCnj(event.target.value))
          setError(null)
        }}
      />
      <button className="button" type="submit">
        Consultar
      </button>
    </form>
  )
}
