import { useApolloClient, useMutation } from '@apollo/client/react'
import { createContext, useCallback, useContext, useEffect, useMemo, useState } from 'react'
import type { ReactNode } from 'react'
import {
  MeDocument,
  SignInDocument,
  SignOutDocument,
  SignUpDocument,
} from '../graphql/generated/graphql'
import { onUnauthenticated } from './unauthenticatedLink'

export type AuthUser = { id: string; email: string }
export type FormError = { code: string; message: string; field: string | null }
export type AuthStatus = 'loading' | 'anonymous' | 'authenticated'

export type AuthContextValue = {
  status: AuthStatus
  user: AuthUser | null
  // True after an explicit sign out, so the redirect goes to /login without
  // a `next` that would bring the user back to the page they just left.
  signedOut: boolean
  signIn: (email: string, password: string) => Promise<FormError[]>
  signUp: (email: string, password: string) => Promise<FormError[]>
  signOut: () => Promise<void>
}

const NETWORK_ERROR: FormError = {
  code: 'NETWORK',
  message: 'Não foi possível concluir agora. Tente novamente.',
  field: null,
}

const AuthContext = createContext<AuthContextValue | null>(null)

type State = { status: AuthStatus; user: AuthUser | null; signedOut: boolean }

// The auth state comes from the `me` query (the session cookie is HttpOnly
// and never read by the SPA). Nothing is written to localStorage or
// sessionStorage (spec 06 requirement 6.7).
export function AuthProvider({ children }: { children: ReactNode }) {
  const client = useApolloClient()
  const [state, setState] = useState<State>({ status: 'loading', user: null, signedOut: false })
  const [signInMutation] = useMutation(SignInDocument)
  const [signUpMutation] = useMutation(SignUpDocument)
  const [signOutMutation] = useMutation(SignOutDocument)

  useEffect(() => {
    let active = true
    client
      .query({ query: MeDocument, fetchPolicy: 'network-only' })
      .then(({ data }) => {
        if (!active) return
        const user = data?.me ?? null
        setState({ status: user ? 'authenticated' : 'anonymous', user, signedOut: false })
      })
      .catch(() => {
        if (active) setState({ status: 'anonymous', user: null, signedOut: false })
      })
    return () => {
      active = false
    }
  }, [client])

  // Any operation answered with UNAUTHENTICATED: the session is gone. The
  // cache is not cleared here (clearing while requests are in flight makes
  // Apollo reject them); it is cleared when the next user signs in.
  useEffect(
    () => onUnauthenticated(() => setState({ status: 'anonymous', user: null, signedOut: false })),
    [],
  )

  const authenticate = useCallback(
    async (
      run: () => Promise<{ user: AuthUser | null; errors: FormError[] } | undefined>,
    ): Promise<FormError[]> => {
      try {
        const payload = await run()
        if (!payload) return [NETWORK_ERROR]
        if (payload.user && payload.errors.length === 0) {
          // Nothing cached by a previous session may leak into this one.
          await client.clearStore()
          setState({ status: 'authenticated', user: payload.user, signedOut: false })
        }
        // Drop __typename and anything else that is not part of the contract.
        return payload.errors.map(({ code, message, field }) => ({ code, message, field }))
      } catch {
        return [NETWORK_ERROR]
      }
    },
    [client],
  )

  const signIn = useCallback(
    (email: string, password: string) =>
      authenticate(async () => {
        const { data } = await signInMutation({ variables: { input: { email, password } } })
        return data?.signIn
      }),
    [authenticate, signInMutation],
  )

  const signUp = useCallback(
    (email: string, password: string) =>
      authenticate(async () => {
        const { data } = await signUpMutation({ variables: { input: { email, password } } })
        return data?.signUp
      }),
    [authenticate, signUpMutation],
  )

  const signOut = useCallback(async () => {
    try {
      await signOutMutation()
    } catch {
      // The local state is cleared either way; an orphan server session
      // expires on its own after 14 days.
    }
    await client.clearStore()
    setState({ status: 'anonymous', user: null, signedOut: true })
  }, [client, signOutMutation])

  const value = useMemo<AuthContextValue>(
    () => ({ ...state, signIn, signUp, signOut }),
    [state, signIn, signUp, signOut],
  )

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>
}

// eslint-disable-next-line react-refresh/only-export-components
export function useAuth(): AuthContextValue {
  const context = useContext(AuthContext)
  if (!context) throw new Error('useAuth must be used inside <AuthProvider>')
  return context
}
