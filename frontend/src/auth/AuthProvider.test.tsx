import { act, render, screen, waitFor } from '@testing-library/react'
import { useEffect } from 'react'
import { ApolloProvider } from '@apollo/client/react'
import { HttpResponse, graphql } from 'msw'
import { describe, expect, it, vi } from 'vitest'
import { server } from '../test/msw/server'
import { createTestClient } from '../test/render'
import { AuthProvider, useAuth } from './AuthProvider'
import type { AuthContextValue } from './AuthProvider'

let latest: AuthContextValue

function Probe() {
  const auth = useAuth()
  useEffect(() => {
    latest = auth
  })
  return (
    <p data-testid="state">
      {auth.status}:{auth.user?.email ?? '-'}:{auth.signedOut ? 'signed-out' : '-'}
    </p>
  )
}

function setup() {
  const client = createTestClient()
  render(
    <ApolloProvider client={client}>
      <AuthProvider>
        <Probe />
      </AuthProvider>
    </ApolloProvider>,
  )
  return client
}

const anonymous = () => server.use(graphql.query('Me', () => HttpResponse.json({ data: { me: null } })))

describe('AuthProvider', () => {
  it('starts loading, then becomes authenticated when me returns a user', async () => {
    setup()
    expect(screen.getByTestId('state')).toHaveTextContent('loading')
    await waitFor(() => expect(screen.getByTestId('state')).toHaveTextContent('authenticated:ana@example.com'))
  })

  it('becomes anonymous when me returns null', async () => {
    anonymous()
    setup()
    await waitFor(() => expect(screen.getByTestId('state')).toHaveTextContent('anonymous:-'))
  })

  it('becomes anonymous when the me request fails', async () => {
    server.use(graphql.query('Me', () => HttpResponse.error()))
    setup()
    await waitFor(() => expect(screen.getByTestId('state')).toHaveTextContent('anonymous:-'))
  })

  it('signs in: returns no errors and exposes the user', async () => {
    anonymous()
    setup()
    await waitFor(() => expect(latest.status).toBe('anonymous'))
    let errors: unknown
    await act(async () => {
      errors = await latest.signIn('ana@example.com', 'a-very-safe-password')
    })
    expect(errors).toEqual([])
    expect(screen.getByTestId('state')).toHaveTextContent('authenticated:ana@example.com')
  })

  it('returns the server errors on a failed sign in and stays anonymous', async () => {
    anonymous()
    setup()
    await waitFor(() => expect(latest.status).toBe('anonymous'))
    let errors: unknown
    await act(async () => {
      errors = await latest.signIn('ana@example.com', 'wrong-password-1')
    })
    expect(errors).toEqual([{ code: 'UNAUTHENTICATED', message: 'E-mail ou senha inválidos.', field: null }])
    expect(latest.status).toBe('anonymous')
  })

  it('returns a generic error when the network fails', async () => {
    anonymous()
    server.use(graphql.mutation('SignIn', () => HttpResponse.error()))
    setup()
    await waitFor(() => expect(latest.status).toBe('anonymous'))
    let errors: Array<{ code: string; message: string }> = []
    await act(async () => {
      errors = await latest.signIn('ana@example.com', 'a-very-safe-password')
    })
    expect(errors).toHaveLength(1)
    expect(errors[0].message).toBe('Não foi possível concluir agora. Tente novamente.')
  })

  it('signs up and exposes field errors', async () => {
    anonymous()
    setup()
    await waitFor(() => expect(latest.status).toBe('anonymous'))
    let errors: Array<{ field: string | null }> = []
    await act(async () => {
      errors = await latest.signUp('taken@example.com', 'a-very-safe-password')
    })
    expect(errors).toEqual([expect.objectContaining({ code: 'VALIDATION_FAILED', field: 'email' })])
    await act(async () => {
      errors = await latest.signUp('new@example.com', 'a-very-safe-password')
    })
    expect(errors).toEqual([])
    expect(latest.status).toBe('authenticated')
  })

  it('signs out: calls the mutation, clears the Apollo cache and marks signed-out', async () => {
    const client = setup()
    await waitFor(() => expect(latest.status).toBe('authenticated'))
    const clearStore = vi.spyOn(client, 'clearStore')
    await act(async () => {
      await latest.signOut()
    })
    expect(clearStore).toHaveBeenCalled()
    expect(screen.getByTestId('state')).toHaveTextContent('anonymous:-:signed-out')
  })

  it('still signs out locally when the sign out request fails', async () => {
    server.use(graphql.mutation('SignOut', () => HttpResponse.error()))
    setup()
    await waitFor(() => expect(latest.status).toBe('authenticated'))
    await act(async () => {
      await latest.signOut()
    })
    expect(latest.status).toBe('anonymous')
  })

  it('becomes anonymous when any operation reports UNAUTHENTICATED', async () => {
    const client = setup()
    await waitFor(() => expect(latest.status).toBe('authenticated'))
    server.use(
      graphql.query('Lawsuit', () =>
        HttpResponse.json({ data: { lawsuit: { lawsuit: null, errors: [{ code: 'UNAUTHENTICATED', message: 'x', field: null }] } } }),
      ),
    )
    const { LawsuitDocument } = await import('../graphql/generated/graphql')
    await client.query({ query: LawsuitDocument, variables: { number: '1001399-31.2023.8.26.0070' }, fetchPolicy: 'network-only' })
    await waitFor(() => expect(latest.status).toBe('anonymous'))
    expect(latest.signedOut).toBe(false)
  })

  it('never writes credentials or tokens to web storage', async () => {
    const local = vi.spyOn(Storage.prototype, 'setItem')
    anonymous()
    setup()
    await waitFor(() => expect(latest.status).toBe('anonymous'))
    await act(async () => {
      await latest.signIn('ana@example.com', 'a-very-safe-password')
    })
    expect(local).not.toHaveBeenCalled()
    expect(localStorage.length).toBe(0)
    expect(sessionStorage.length).toBe(0)
    local.mockRestore()
  })

  it('throws a helpful error when used outside the provider', () => {
    const spy = vi.spyOn(console, 'error').mockImplementation(() => {})
    expect(() => render(<Probe />)).toThrow(/AuthProvider/)
    spy.mockRestore()
  })
})
