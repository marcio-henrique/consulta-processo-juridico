# Requirements: Lawsuit lookup API

## Introduction

GraphQL read API to find a lawsuit by CNJ number and page through its movements. Challenge items: FR 3 (data for the lawsuit page), differentials 1 (Rails) and 3 (GraphQL). Authentication is added to these operations by spec 06 (task AU-4). Related: [lawsuit-lookup](../../../docs/domains/lawsuit-lookup.md), [architecture](../../../docs/architecture.md) section 4, [ADR-0005](../../../docs/adr/0005-movement-ordering-and-idempotent-import.md).

## Requirements

### Requirement 1: Find a lawsuit by number

**User Story:** As a user, I want to look up a lawsuit by its CNJ number in any common format, so that I do not have to retype it.

#### Acceptance Criteria
1. WHEN `lawsuit(number:)` receives a valid CNJ number, formatted or digits-only, with optional surrounding whitespace, and the lawsuit exists, THEN the system SHALL return the lawsuit and an empty `errors` list.
2. IF the number is not a valid CNJ (length or check digits), THEN the system SHALL return `lawsuit: null` and an error with code `INVALID_CNJ` and `field: "number"`.
3. IF the number is valid but no lawsuit exists, THEN the system SHALL return `lawsuit: null` and an error with code `NOT_FOUND`.
4. THE system SHALL NOT raise a GraphQL top-level error for cases 2 and 3.
5. THE lookup SHALL be exact on the canonical number and SHALL NOT use `LIKE` or prefix matching.

### Requirement 2: Lawsuit fields

**User Story:** As the UI, I want all the lawsuit data in one request, so that the page renders quickly.

#### Acceptance Criteria
1. THE `Lawsuit` type SHALL expose `number`, `forum`, `court`, `numberOfAuthors`, `value` and `movementsCount`.
2. THE `value` field SHALL be a `Money` object with `amount` (decimal string, for example `"8000.00"`) and `formatted` (pt-BR currency, for example `"R$ 8.000,00"`).
3. THE `Lawsuit` type SHALL expose `latestSummary` (added by spec 04) and `movements`.

### Requirement 3: Movements, ordering and pagination

**User Story:** As a user, I want movements newest first, with predictable paging.

#### Acceptance Criteria
1. THE `movements` connection SHALL return items ordered by `occurred_on DESC`, then `source_row ASC`.
2. THE connection SHALL accept `first` (default 25, maximum 100) and `after` (opaque cursor), and SHALL return `pageInfo { hasNextPage endCursor }` and `nodes`.
3. IF `first` exceeds 100 or is not positive, THEN the system SHALL return a `UserError` with code `INVALID_ARGUMENT` for that field.
4. WHEN paging through all pages, THEN the concatenated results SHALL equal the full ordered list without duplicates or gaps, including for movements sharing the same date.
5. THE `Movement` type SHALL expose `id`, `date` (ISO 8601 date), `title` and nullable `content`.

### Requirement 4: Error conventions and shared types

**User Story:** As a client developer, I want predictable errors.

#### Acceptance Criteria
1. THE schema SHALL define `UserError { code: ErrorCode!, message: String!, field: String }` and the `ErrorCode` enum with at least `INVALID_CNJ`, `NOT_FOUND`, `INVALID_ARGUMENT`, `UNAUTHENTICATED`, `SUMMARY_UNAVAILABLE`, `RATE_LIMITED`, `VALIDATION_FAILED`.
2. THE `message` of each error SHALL be in pt-BR and safe to show to users.
3. IF an unexpected exception occurs in a resolver, THEN the system SHALL log it with the request id and return a generic top-level error without internal details.

### Requirement 5: Performance and safety

**User Story:** As an operator, I want the API to be efficient and bounded.

#### Acceptance Criteria
1. WHEN the lawsuit query requests the lawsuit, a page of movements and `movementsCount`, THEN the system SHALL execute a constant number of SQL queries (no N+1), verified by a test.
2. THE schema SHALL enforce a maximum query depth of 10 and a maximum complexity configured in the schema.
3. THE committed `backend/schema.graphql` SHALL match the schema (CI drift check from spec 01).
