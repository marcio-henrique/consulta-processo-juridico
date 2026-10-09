import { ApolloLink } from '@apollo/client'
import { tap } from 'rxjs'

type Listener = () => void
const listeners = new Set<Listener>()

// The Apollo client lives outside React, so the link reports through this
// tiny event hub and AuthProvider subscribes to it.
export function onUnauthenticated(listener: Listener): () => void {
  listeners.add(listener)
  return () => {
    listeners.delete(listener)
  }
}

function hasUnauthenticatedError(result: {
  data?: unknown
  errors?: ReadonlyArray<{ extensions?: Record<string, unknown> }>
}): boolean {
  if (result.errors?.some((error) => error.extensions?.code === 'UNAUTHENTICATED')) return true
  const data = result.data
  if (!data || typeof data !== 'object') return false
  // Payload convention: every operation field may carry errors: [{ code }].
  return Object.values(data).some((field) => {
    const errors = (field as { errors?: unknown } | null)?.errors
    return Array.isArray(errors) && errors.some((error) => error?.code === 'UNAUTHENTICATED')
  })
}

// Any operation answered with UNAUTHENTICATED means the session is gone
// (spec 06 requirement 6.6). SignIn is excluded: there, UNAUTHENTICATED is
// the "wrong e-mail or password" answer.
export function createUnauthenticatedLink() {
  return new ApolloLink((operation, forward) =>
    forward(operation).pipe(
      tap((result) => {
        if (operation.operationName === 'SignIn') return
        if (hasUnauthenticatedError(result)) listeners.forEach((listener) => listener())
      }),
    ),
  )
}
