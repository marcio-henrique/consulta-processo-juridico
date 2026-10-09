import { ApolloProvider } from '@apollo/client/react'
import { HttpLink } from '@apollo/client/link/http'
import { render } from '@testing-library/react'
import type { ReactElement } from 'react'
import { MemoryRouter } from 'react-router-dom'
import { AuthProvider } from '../auth/AuthProvider'
import { createApolloClient } from '../graphql/apolloClient'

type Options = {
  route?: string
  client?: ReturnType<typeof createApolloClient>
}

// Absolute URI: Node's fetch cannot resolve the relative '/graphql' of the
// real client. MSW matches operations by name, so the host does not matter.
export function createTestClient() {
  return createApolloClient(new HttpLink({ uri: 'http://localhost/graphql' }))
}

// Same tree as main.tsx: Apollo > Router > Auth. By default the MSW `Me`
// handler answers with a signed-in user; override it for anonymous scenarios.
export function renderWithProviders(ui: ReactElement, { route = '/', client }: Options = {}) {
  const apollo = client ?? createTestClient()
  const utils = render(
    <ApolloProvider client={apollo}>
      <MemoryRouter initialEntries={[route]}>
        <AuthProvider>{ui}</AuthProvider>
      </MemoryRouter>
    </ApolloProvider>,
  )
  return { ...utils, client: apollo }
}
