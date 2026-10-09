import type { InputHTMLAttributes, Ref } from 'react'

type Props = Omit<InputHTMLAttributes<HTMLInputElement>, 'id' | 'aria-invalid'> & {
  id: string
  label: string
  hint?: string
  error?: string | null
  // Extra element ids that describe the field (for example a form-level alert).
  describedBy?: string
  inputRef?: Ref<HTMLInputElement>
}

// Visible label, optional hint before the field, and an inline error linked
// with aria-describedby and announced via role="alert" (WCAG 1.3.1, 3.3.1,
// 3.3.2, 4.1.3). Required state is stated in text, not only by color.
export function TextField({ id, label, hint, error, describedBy: extraDescribedBy, inputRef, required, ...input }: Props) {
  const hintId = hint ? `${id}-hint` : undefined
  const errorId = error ? `${id}-error` : undefined
  const describedBy = [hintId, errorId, extraDescribedBy].filter(Boolean).join(' ') || undefined

  return (
    <div className="field">
      <label className="field__label" htmlFor={id}>
        {label}
        {required ? <span className="field__required"> (obrigatório)</span> : null}
      </label>
      {hint ? (
        <span className="field__hint" id={hintId}>
          {hint}
        </span>
      ) : null}
      <input
        {...input}
        id={id}
        ref={inputRef}
        className="field__input"
        required={required}
        aria-invalid={error ? true : undefined}
        aria-describedby={describedBy}
      />
      {error ? (
        <p className="field__error" id={errorId} role="alert">
          {error}
        </p>
      ) : null}
    </div>
  )
}
