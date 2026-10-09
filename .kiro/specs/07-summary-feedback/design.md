# Design: Summary feedback

## Overview

A small table, one service with upsert semantics, one mutation, one field and two buttons.

## Data model

```ruby
create_table :summary_feedbacks do |t|
  t.references :summary, null: false, foreign_key: { on_delete: :cascade }
  t.references :user,    null: false, foreign_key: { on_delete: :cascade }
  t.boolean :helpful, null: false
  t.timestamps
end
add_index :summary_feedbacks, [:summary_id, :user_id], unique: true
```

## Backend components

| Component | Location | Responsibility |
|-----------|----------|----------------|
| `SummaryFeedback` | `app/models/summary_feedback.rb` | Associations, validations (`helpful` inclusion in `[true, false]`) |
| `Feedback::Rate` | `app/services/feedback/rate.rb` | `call(user:, summary_id:, helpful:)`; `upsert` on `(summary_id, user_id)`; returns result |
| `Types::Mutations::RateSummary` | `app/graphql/mutations/rate_summary.rb` | Thin |
| `Summary.myFeedback` | `types/summary_type.rb` | Uses a Dataloader keyed by `(summary_id, current_user.id)` |
| `feedback:report` | `lib/tasks/feedback.rake` | Aggregation SQL grouped by `summaries.prompt_version, summaries.model` |

## GraphQL

```graphql
type SummaryFeedback { summaryId: ID!, helpful: Boolean! }
type RateSummaryPayload { feedback: SummaryFeedback, errors: [UserError!]! }
extend type Mutation { rateSummary(summaryId: ID!, helpful: Boolean!): RateSummaryPayload! }
extend type Summary { myFeedback: Boolean }
```

`Feedback::Rate` uses `SummaryFeedback.upsert({summary_id:, user_id:, helpful:}, unique_by: [:summary_id, :user_id])` so concurrent clicks do not raise.

## Frontend components

| Component | Behavior |
|-----------|----------|
| `FeedbackButtons` | Props: `summaryId`, `value: boolean | null`. Two buttons with `aria-pressed`. Uses `useMutation` with `optimisticResponse` and cache update on `Summary.myFeedback` |
| `SummaryCard` | Renders `FeedbackButtons` only in `ready` state |

Copy: question "Este resumo foi útil?"; buttons "Útil" / "Não foi útil"; success "Obrigado pelo feedback."; failure "Não foi possível registrar seu voto."

## Report output (example)

```
prompt_version  model         summaries  votes  helpful  not_helpful  helpful_rate
v1              <model-id>    42         17     14       3            82.4%
```

## Error handling

| Case | Result |
|------|--------|
| Anonymous | `UNAUTHENTICATED` (guard from spec 06) |
| Unknown `summaryId` | `NOT_FOUND` |
| Concurrent same-user clicks | Upsert, last write wins |
| Network failure in UI | Revert optimistic state, show message |

## Testing strategy

- Model: validations, unique index (DB-level violation test).
- `Feedback::Rate`: create, change vote, same value twice, other user independent, unknown summary, concurrent calls (two threads) leave one row.
- Request specs: mutation shapes; anonymous rejected; `myFeedback` null/true/false and per-user isolation; no field exposes other users' votes.
- Rake: report with votes, without votes, no emails/ids in output.
- UI: initial pressed state from `myFeedback`, optimistic update, rollback on failure, clicking active button keeps value, hidden in loading/error states, `aria-live` message.
