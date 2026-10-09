# Tasks: Lawsuit lookup API

Lead: Backend. Status: done (L-1..L-5). Definition of done verified against the real database.

## 4-hour execution board (overrides the hour estimates below)

Schedule and ownership: [EXECUTION-PLAN-4H](../../../docs/plan/EXECUTION-PLAN-4H.md). The schema is already fixed in [docs/contracts/schema.graphql](../../../docs/contracts/schema.graphql); stubs exist after F-10.

| Task | Lane | ⏱ min | After |
|------|------|------:|-------|
| L-1 Shared types, error conventions, limits hook | B1 | 10 | F-10 |
| L-2 `Lawsuits::Find` and the `lawsuit` query | B1 | 10 | L-1, I-1 (from B2) |
| L-3 Movements connection: ordering, pagination | B1 | 15 | L-2 |
| L-4 Query-count guard | B1 | 8 | L-3 |
| L-5 Schema dump and docs | B1 | 4 | L-4 |

Test data for these tasks: [contracts](../../../docs/contracts/README.md) section 4 (known lawsuit, longest lawsuit with 120 movements, tie-break example).

- [x] **L-1. Shared GraphQL types and error conventions** (0.5 h)
  - `UserError`, `ErrorCode`, `Money` (+ `MoneyFormatter`), payload conventions, `rescue_from` for unexpected errors, depth and complexity limits.
  - Red: formatter spec; schema spec for depth limit; spec that an unexpected error returns a generic message and logs the request id.
  - _Requirements: 4.1, 4.2, 4.3, 5.2, 2.2_

- [x] **L-2. `Lawsuits::Find` and the `lawsuit` query** (0.5 h)
  - Red: service spec (formatted, digits-only, whitespace, invalid, not found); request spec for payload shapes.
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 2.1, 2.3_

- [x] **L-3. Movements connection: ordering and pagination** (0.75 h)
  - Red: same-date items ordered by `source_row`; full traversal across pages equals the full list; `first` default 25, max 100, invalid values return `INVALID_ARGUMENT`.
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5_

- [x] **L-4. Query-count guard** (0.5 h)
  - Use `GraphQL::Dataloader`; add a test that counts SQL queries for the full lawsuit query and fails above the bound (expected: lawsuit, movements page, count).
  - _Requirements: 5.1_

- [x] **L-5. Schema dump and docs** (0.25 h)
  - Regenerate `backend/schema.graphql`; update `architecture.md` section 4 if the schema differs; run [finish-delivery-docs](../../../docs/skills/finish-delivery-docs.md).
  - _Requirements: 5.3_

## Notes
- `latestSummary` is added to `Lawsuit` by spec 04 (A-10). `UNAUTHENTICATED` enforcement is added by spec 06 (AU-4); tests written here use a helper that can sign in later without rewriting them (`graphql_request(query, variables:, user: nil)`).

## Definition of done (spec)
- [x] Querying the real database for `1001399-31.2023.8.26.0070` returns Foro de Batatais, 2ª Vara Cível, R$ 10.000,00 and paged movements.
- [x] The challenge's example number returns `NOT_FOUND`; a number with a bad check digit returns `INVALID_CNJ`.
- [x] Gate green; schema dump committed.
