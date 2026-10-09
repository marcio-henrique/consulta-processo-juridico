import { useQuery } from '@apollo/client/react'
import { useState } from 'react'
import { useParams } from 'react-router-dom'
import { LawsuitData } from '../components/LawsuitData'
import { LawsuitHeader } from '../components/LawsuitHeader'
import { MovementsTable } from '../components/MovementsTable'
import { PageState } from '../components/PageState'
import { SummaryCard } from '../components/SummaryCard'
import { LawsuitDocument } from '../graphql/generated/graphql'
import { usePageTitle } from '../lib/usePageTitle'
import { useGenerateSummary } from './useGenerateSummary'

const NOT_FOUND_CODES = ['NOT_FOUND', 'INVALID_CNJ']

export function LawsuitPage() {
  const { number: urlNumber = '' } = useParams()
  const { data, error, refetch, fetchMore } = useQuery(LawsuitDocument, {
    variables: { number: urlNumber },
    // A retry after a failure must hit the network again.
    notifyOnNetworkStatusChange: false,
  })
  const [loadingMore, setLoadingMore] = useState(false)

  const payload = data?.lawsuit
  const lawsuit = payload?.lawsuit ?? null
  const notFound = payload?.errors.some((e) => NOT_FOUND_CODES.includes(e.code)) ?? false
  const failed = Boolean(error) || (payload !== undefined && !lawsuit && !notFound)

  const summary = useGenerateSummary(lawsuit?.number, Boolean(lawsuit?.latestSummary))

  usePageTitle(
    lawsuit
      ? `Processo ${lawsuit.number}`
      : notFound
        ? 'Processo não encontrado'
        : failed
          ? 'Erro ao consultar processo'
          : `Processo ${urlNumber}`,
  )

  if (notFound) {
    return (
      <>
        <LawsuitHeader heading="Processo não encontrado na base." />
        <PageState kind="not-found" />
      </>
    )
  }

  if (failed) {
    return (
      <>
        <LawsuitHeader heading="Erro ao consultar o processo" />
        <PageState kind="error" onRetry={() => void refetch()} />
      </>
    )
  }

  if (!lawsuit) {
    return (
      <>
        <LawsuitHeader number={urlNumber} />
        <PageState kind="loading" />
      </>
    )
  }

  const { movements } = lawsuit
  const summaryStatus = lawsuit.latestSummary
    ? 'ready'
    : summary.status === 'error'
      ? 'error'
      : 'loading'

  async function loadMore() {
    setLoadingMore(true)
    try {
      await fetchMore({ variables: { number: urlNumber, after: movements.pageInfo.endCursor } })
    } finally {
      setLoadingMore(false)
    }
  }

  return (
    <>
      <LawsuitHeader number={lawsuit.number} />
      <LawsuitData lawsuit={lawsuit} />
      <SummaryCard
        status={summaryStatus}
        body={lawsuit.latestSummary?.body}
        summaryId={lawsuit.latestSummary?.id}
        myFeedback={lawsuit.latestSummary?.myFeedback}
        onRetry={() => void summary.retry()}
      />
      <MovementsTable
        movements={movements.nodes}
        total={lawsuit.movementsCount}
        hasMore={movements.pageInfo.hasNextPage}
        loadingMore={loadingMore}
        onLoadMore={() => void loadMore()}
      />
    </>
  )
}
