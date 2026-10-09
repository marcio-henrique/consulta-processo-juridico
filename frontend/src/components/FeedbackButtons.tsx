import { useMutation } from '@apollo/client/react'
import { useState } from 'react'
import { RateSummaryDocument, type RateSummaryMutation } from '../graphql/generated/graphql'

export const FEEDBACK_QUESTION = 'Este resumo foi útil?'
export const FEEDBACK_THANKS = 'Obrigado pelo feedback.'
export const FEEDBACK_FAILURE = 'Não foi possível registrar seu voto.'

type Props = {
  summaryId: string
  /** The current user's vote: true, false or null (not voted yet). */
  value: boolean | null | undefined
}

// Vote buttons for a ready summary. The vote lives in the Apollo cache
// (Summary.myFeedback): the mutation writes it optimistically and Apollo
// rolls it back by itself if the request fails, so `value` is always the
// source of truth for aria-pressed.
export function FeedbackButtons({ summaryId, value }: Props) {
  const [rate] = useMutation(RateSummaryDocument)
  const [message, setMessage] = useState('')
  const [failed, setFailed] = useState(false)

  function fail(didFail: boolean) {
    setFailed(didFail)
    setMessage(didFail ? FEEDBACK_FAILURE : FEEDBACK_THANKS)
  }

  async function vote(helpful: boolean) {
    // Clicking the active button keeps the vote: no toggle off, no request.
    if (value === helpful) return
    setMessage('')
    setFailed(false)
    try {
      const { data } = await rate({
        variables: { summaryId, helpful },
        // The generated types omit __typename, which the optimistic layer needs.
        optimisticResponse: {
          rateSummary: {
            __typename: 'RateSummaryPayload',
            feedback: { __typename: 'SummaryFeedback', summaryId, helpful },
            errors: [],
          },
        } as unknown as RateSummaryMutation,
        update(cache, { data: result }) {
          if (!result?.rateSummary.feedback || result.rateSummary.errors.length > 0) return
          cache.modify({
            id: cache.identify({ __typename: 'Summary', id: summaryId }),
            fields: { myFeedback: () => result.rateSummary.feedback?.helpful ?? null },
          })
        },
      })
      fail(Boolean(data?.rateSummary.errors.length))
    } catch {
      fail(true)
    }
  }

  return (
    <div className="feedback">
      <div role="group" aria-labelledby="feedback-question" className="feedback__group">
        <p id="feedback-question" className="feedback__question">
          {FEEDBACK_QUESTION}
        </p>
        <button
          type="button"
          className="button button--secondary feedback__button"
          aria-pressed={value === true}
          onClick={() => void vote(true)}
        >
          {value === true ? <span aria-hidden="true">✓ </span> : null}Útil
        </button>
        <button
          type="button"
          className="button button--secondary feedback__button"
          aria-pressed={value === false}
          onClick={() => void vote(false)}
        >
          {value === false ? <span aria-hidden="true">✓ </span> : null}Não foi útil
        </button>
      </div>
      <p
        className={failed ? 'feedback__message feedback__message--error' : 'feedback__message'}
        aria-live="polite"
      >
        {message}
      </p>
    </div>
  )
}
