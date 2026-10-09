import { useEffect, useRef, useState } from 'react'
import type { FormEvent } from 'react'
import { Link } from 'react-router-dom'
import type { FormError } from '../auth/AuthProvider'
import { TextField } from './TextField'

type Props = {
  idPrefix: string
  heading: string
  submitLabel: string
  passwordAutoComplete: 'current-password' | 'new-password'
  passwordHint?: string
  onSubmit: (email: string, password: string) => Promise<FormError[]>
  alternative: { text: string; to: string }
}

type FieldErrors = { email?: string; password?: string }

// Shared by the login and sign-up pages. Accessibility (WCAG 2.2 AA):
// visible labels, autocomplete tokens, errors in text linked with
// aria-describedby and announced via role="alert", focus on the first invalid
// field, entered data kept after an error, paste and password managers allowed.
export function AuthForm({
  idPrefix,
  heading,
  submitLabel,
  passwordAutoComplete,
  passwordHint,
  onSubmit,
  alternative,
}: Props) {
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [fieldErrors, setFieldErrors] = useState<FieldErrors>({})
  const [formError, setFormError] = useState<string | null>(null)
  const [submitting, setSubmitting] = useState(false)
  // Incremented on every failed submit so focus moves even if the same error repeats.
  const [attempt, setAttempt] = useState(0)
  const emailRef = useRef<HTMLInputElement>(null)
  const passwordRef = useRef<HTMLInputElement>(null)
  const formErrorId = `${idPrefix}-form-error`

  useEffect(() => {
    if (attempt === 0) return
    if (fieldErrors.password && !fieldErrors.email && !formError) passwordRef.current?.focus()
    else emailRef.current?.focus()
    // Only react to a new failed attempt, not to every keystroke.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [attempt])

  function fail(fields: FieldErrors, form: string | null) {
    setFieldErrors(fields)
    setFormError(form)
    setAttempt((value) => value + 1)
  }

  async function handleSubmit(event: FormEvent) {
    event.preventDefault()
    if (submitting) return

    const missing: FieldErrors = {}
    if (!email.trim()) missing.email = 'Informe o e-mail.'
    if (!password) missing.password = 'Informe a senha.'
    if (missing.email || missing.password) {
      fail(missing, null)
      return
    }

    setSubmitting(true)
    const errors = await onSubmit(email, password)
    setSubmitting(false)
    if (errors.length === 0) return // the page redirects once the session exists

    const fields: FieldErrors = {}
    let form: string | null = null
    for (const error of errors) {
      if (error.field === 'email' && !fields.email) fields.email = error.message
      else if (error.field === 'password' && !fields.password) fields.password = error.message
      else form ??= error.message
    }
    fail(fields, form)
  }

  return (
    <form className="auth-card" onSubmit={handleSubmit} noValidate aria-labelledby={`${idPrefix}-title`}>
      <h1 id={`${idPrefix}-title`}>{heading}</h1>

      {formError ? (
        <p className="alert" id={formErrorId} role="alert">
          {formError}
        </p>
      ) : null}

      <TextField
        id={`${idPrefix}-email`}
        name="email"
        type="email"
        label="E-mail"
        required
        autoComplete="email"
        autoCapitalize="none"
        spellCheck={false}
        value={email}
        error={fieldErrors.email}
        describedBy={formError ? formErrorId : undefined}
        inputRef={emailRef}
        onChange={(event) => {
          setEmail(event.target.value)
          setFieldErrors((current) => ({ ...current, email: undefined }))
        }}
      />
      <TextField
        id={`${idPrefix}-password`}
        name="password"
        type="password"
        label="Senha"
        required
        hint={passwordHint}
        autoComplete={passwordAutoComplete}
        value={password}
        error={fieldErrors.password}
        inputRef={passwordRef}
        onChange={(event) => {
          setPassword(event.target.value)
          setFieldErrors((current) => ({ ...current, password: undefined }))
        }}
      />

      <button className="button" type="submit" disabled={submitting}>
        {submitLabel}
      </button>
      <p className="auth-card__alt">
        <Link to={alternative.to}>{alternative.text}</Link>
      </p>
    </form>
  )
}
