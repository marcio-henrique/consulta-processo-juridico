import { ApolloClient, ApolloLink, InMemoryCache } from '@apollo/client'
import { HttpLink } from '@apollo/client/link/http'
import { createUnauthenticatedLink } from '../auth/unauthenticatedLink'

// Same-origin by design (architecture.md section 7): the Vite dev server
// proxies /graphql to the api container, and in production the SPA and API
// share an origin behind a reverse proxy. credentials: 'same-origin' lets
// the session cookie (_lawsuit_session) travel with every request without
// needing CORS.
export const httpLink = new HttpLink({
  uri: '/graphql',
  credentials: 'same-origin',
})

type MovementsConnection = {
  nodes?: readonly unknown[]
  pageInfo?: unknown
}

// Normalized entries are references; identical references mean the same row.
const refOf = (node: unknown) => (node as { __ref?: string }).__ref ?? JSON.stringify(node)

export function createCache() {
  return new InMemoryCache({
    typePolicies: {
      // The canonical CNJ number identifies a lawsuit, so a lookup by digits
      // only and by formatted number resolve to the same cache entry.
      Lawsuit: {
        keyFields: ['number'],
        fields: {
          // "Carregar mais": every page is appended to a single list.
          movements: {
            keyArgs: false,
            merge(existing: MovementsConnection | undefined, incoming: MovementsConnection) {
              const seen = new Set((existing?.nodes ?? []).map(refOf))
              const fresh = (incoming.nodes ?? []).filter((node) => !seen.has(refOf(node)))
              return { ...incoming, nodes: [...(existing?.nodes ?? []), ...fresh] }
            },
          },
        },
      },
    },
  })
}

export function createApolloClient(link: ApolloClient.Options['link'] = httpLink) {
  return new ApolloClient({
    link: ApolloLink.from([createUnauthenticatedLink(), link]),
    cache: createCache(),
  })
}

export const apolloClient = createApolloClient()
