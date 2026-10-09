import { ApolloLink, gql } from '@apollo/client'
import { Observable } from 'rxjs'
import { describe, expect, it, vi } from 'vitest'
import { createApolloClient } from '../graphql/apolloClient'
import { onUnauthenticated } from './unauthenticatedLink'

// A terminating link that answers every operation with a canned result; the
// real client wraps it with the unauthenticated link, like in production.
async function run(result: object, name = 'Anything') {
  const terminating = new ApolloLink(
    () =>
      new Observable((subscriber) => {
        subscriber.next(result as never)
        subscriber.complete()
      }),
  )
  const client = createApolloClient(terminating)
  const listener = vi.fn()
  const stop = onUnauthenticated(listener)
  const query = gql(`query ${name} { lawsuit(number: "1") { errors { code } } }`)
  await client.query({ query, fetchPolicy: 'no-cache' }).catch(() => undefined)
  stop()
  return listener
}

describe('createUnauthenticatedLink', () => {
  it('notifies when a payload carries an UNAUTHENTICATED user error', async () => {
    const listener = await run({ data: { lawsuit: { errors: [{ code: 'UNAUTHENTICATED' }] } } })
    expect(listener).toHaveBeenCalledTimes(1)
  })

  it('notifies when the top-level errors carry the UNAUTHENTICATED code', async () => {
    const listener = await run({ errors: [{ message: 'x', extensions: { code: 'UNAUTHENTICATED' } }] })
    expect(listener).toHaveBeenCalledTimes(1)
  })

  it('ignores other error codes and successful results', async () => {
    expect(await run({ data: { lawsuit: { errors: [{ code: 'NOT_FOUND' }] } } })).not.toHaveBeenCalled()
    expect(await run({ data: { lawsuit: { errors: [] } } })).not.toHaveBeenCalled()
    expect(await run({ data: { lawsuit: null } })).not.toHaveBeenCalled()
    expect(await run({ data: null })).not.toHaveBeenCalled()
  })

  it('ignores SignIn, where UNAUTHENTICATED means wrong credentials', async () => {
    const listener = await run({ data: { lawsuit: { errors: [{ code: 'UNAUTHENTICATED' }] } } }, 'SignIn')
    expect(listener).not.toHaveBeenCalled()
  })

  it('stops notifying after unsubscribe', async () => {
    const terminating = new ApolloLink(
      () =>
        new Observable((subscriber) => {
          subscriber.next({ data: { lawsuit: { errors: [{ code: 'UNAUTHENTICATED' }] } } } as never)
          subscriber.complete()
        }),
    )
    const listener = vi.fn()
    onUnauthenticated(listener)()
    await createApolloClient(terminating)
      .query({ query: gql`query Anything { lawsuit(number: "1") { errors { code } } }`, fetchPolicy: 'no-cache' })
      .catch(() => undefined)
    expect(listener).not.toHaveBeenCalled()
  })
})
