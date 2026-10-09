import { HttpResponse, graphql } from 'msw'

// Default handlers for tests. Individual tests override with
// server.use(...) for specific scenarios. No operations are mocked yet;
// this is the harness, filled in by spec 05 as GraphQL operations land.
const link = graphql.link('/graphql')

export const handlers = [
  link.query('__ping', () => {
    return HttpResponse.json({ data: { __typename: 'Query' } })
  }),
]
