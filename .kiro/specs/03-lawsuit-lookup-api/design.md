# Design: Lawsuit lookup API

## Overview

A thin GraphQL layer over a `Lawsuits::Find` service. Shared error types live in a base module so later specs reuse them.

## Components

| Component | Location | Responsibility |
|-----------|----------|----------------|
| `Types::UserErrorType`, `Types::ErrorCode` | `app/graphql/types/` | Shared error shape and codes |
| `Types::MoneyType` | `app/graphql/types/money_type.rb` | `amount`, `formatted` |
| `Types::LawsuitType`, `Types::MovementType` | `app/graphql/types/` | Output types; `movements` connection field |
| `Types::LawsuitPayloadType` | `app/graphql/types/` | `{ lawsuit, errors }` |
| `Resolvers::LawsuitResolver` or field method on `QueryType` | `app/graphql/types/query_type.rb` | Calls `Lawsuits::Find` |
| `Lawsuits::Find` | `app/services/lawsuits/find.rb` | Normalize with `CnjNumber`, fetch, return result |
| `Money::Formatter` | `app/lib/money_formatter.rb` | pt-BR currency from `BigDecimal` |
| Cursor pagination | `app/graphql/connections/` or `GraphQL::Pagination::ActiveRecordRelationConnection` | Stable ordering with composite order |

## Interfaces

```graphql
type Query {
  lawsuit(number: String!): LawsuitPayload!
}
type LawsuitPayload { lawsuit: Lawsuit, errors: [UserError!]! }
type Lawsuit {
  number: String!
  forum: String!
  court: String!
  value: Money!
  numberOfAuthors: Int!
  movementsCount: Int!
  movements(first: Int = 25, after: String): MovementConnection!
}
type MovementConnection { nodes: [Movement!]!, pageInfo: PageInfo! }
type Movement { id: ID!, date: ISO8601Date!, title: String!, content: String }
type Money { amount: String!, formatted: String! }
```

`Lawsuits::Find.call(raw)` returns `Result(lawsuit:, error_code:)`. The type layer maps `error_code` to `UserError` with the pt-BR message from one place (`Errors::Messages`).

## Ordering and cursors

Relation: `lawsuit.movements.order(occurred_on: :desc, source_row: :asc)`. The built-in connection uses offset-based cursors, which are stable here because movements change only on import. Max page size 100. `movementsCount` uses a single `COUNT` (via Dataloader or `counter`-style batch).

## Data loading

`GraphQL::Dataloader` for associations. For this query shape (one lawsuit, one movements page, one count) three queries are expected; the test asserts a fixed upper bound.

## Messages (pt-BR)

| Code | Message |
|------|---------|
| `INVALID_CNJ` | "Número de processo inválido. Confira os dígitos." |
| `NOT_FOUND` | "Processo não encontrado na base." |
| `INVALID_ARGUMENT` | "Parâmetro inválido." |
| `UNAUTHENTICATED` | "Faça login para continuar." |

## Error handling

Expected errors are returned in `errors`. Unexpected exceptions are rescued in `Schema.rescue_from(StandardError)`: log class, message and request id (no params), return `GraphQL::ExecutionError` with "Erro interno. Tente novamente." No stack traces to clients, in any environment except `development` where Rails already shows them in logs.

## Testing strategy

- `spec/lib/money_formatter_spec.rb`: `8000` -> `R$ 8.000,00`, `13028.16`, `0`.
- `spec/services/lawsuits/find_spec.rb`: formatted, digits-only, whitespace, invalid, not found.
- `spec/graphql/lawsuit_query_spec.rb` (request specs against `/graphql`): found, invalid, not found, field values, ordering with same-date items, pagination across pages (no duplicates/gaps), `first` limits, query count bound, depth limit rejection.
- Schema dump drift is checked in CI.
