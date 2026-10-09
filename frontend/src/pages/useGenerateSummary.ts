import { gql } from '@apollo/client'
import { useApolloClient, useMutation } from '@apollo/client/react'
import { useCallback, useEffect, useRef, useState } from 'react'
import { GenerateSummaryDocument } from '../graphql/generated/graphql'

export type GenerationStatus = 'idle' | 'loading' | 'error'

const SUMMARY_FRAGMENT = gql`
  fragment GeneratedSummary on Summary {
    id
    body
    generatedAt
    myFeedback
  }
`

// Generates the summary when the lawsuit has none cached. The result is
// written into the Apollo cache (Lawsuit.latestSummary), so the page keeps
// reading a single source and revisiting the lawsuit does not call the
// mutation again.
export function useGenerateSummary(number: string | undefined, hasSummary: boolean) {
  const client = useApolloClient()
  const [mutate] = useMutation(GenerateSummaryDocument)
  const [status, setStatus] = useState<GenerationStatus>('idle')
  // Keyed by lawsuit number so React StrictMode's double effect runs only once.
  const startedFor = useRef<string | null>(null)

  const generate = useCallback(async () => {
    if (!number) return
    setStatus('loading')
    try {
      const { data } = await mutate({ variables: { lawsuitNumber: number } })
      const summary = data?.generateSummary.summary
      if (!summary || (data?.generateSummary.errors.length ?? 0) > 0) {
        setStatus('error')
        return
      }
      const reference = client.cache.writeFragment({
        fragment: SUMMARY_FRAGMENT,
        data: { ...summary, __typename: 'Summary' as const },
      })
      client.cache.modify({
        id: client.cache.identify({ __typename: 'Lawsuit', number }),
        fields: { latestSummary: () => reference },
      })
      setStatus('idle')
    } catch {
      setStatus('error')
    }
  }, [client, mutate, number])

  useEffect(() => {
    if (!number || hasSummary || startedFor.current === number) return
    startedFor.current = number
    void generate()
  }, [number, hasSummary, generate])

  return { status, retry: generate }
}
