import { ApolloClient, InMemoryCache } from '@apollo/client'
import { HttpLink } from '@apollo/client/link/http'

// Same-origin by design (architecture.md section 7): the Vite dev server
// proxies /graphql to the api container, and in production the SPA and API
// share an origin behind a reverse proxy. credentials: 'same-origin' lets
// the session cookie (_lawsuit_session) travel with every request without
// needing CORS.
export const httpLink = new HttpLink({
  uri: '/graphql',
  credentials: 'same-origin',
})

export const apolloClient = new ApolloClient({
  link: httpLink,
  cache: new InMemoryCache(),
})
