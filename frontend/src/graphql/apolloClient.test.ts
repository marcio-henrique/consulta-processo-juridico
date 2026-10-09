import { gql } from '@apollo/client'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import { apolloClient } from './apolloClient'

const PING = gql`
  query Ping {
    __typename
  }
`

describe('apolloClient', () => {
  const originalFetch = globalThis.fetch

  beforeEach(() => {
    globalThis.fetch = vi.fn(
      async () =>
        new Response(JSON.stringify({ data: { __typename: 'Query' } }), {
          headers: { 'Content-Type': 'application/json' },
        }),
    ) as unknown as typeof fetch
  })

  afterEach(() => {
    globalThis.fetch = originalFetch
    apolloClient.cache.reset()
  })

  it('sends queries to the same-origin /graphql endpoint with cookie credentials', async () => {
    await apolloClient.query({ query: PING, fetchPolicy: 'network-only' })

    expect(globalThis.fetch).toHaveBeenCalledTimes(1)
    const [url, init] = (globalThis.fetch as unknown as ReturnType<typeof vi.fn>).mock.calls[0] as [
      string,
      RequestInit,
    ]

    expect(url).toBe('/graphql')
    expect(init.credentials).toBe('same-origin')
  })
})
