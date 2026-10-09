# ADR-0005: Movement ordering and idempotent import

- Status: Accepted
- Date: 2026-10-07
- Deciders: Project owner, Architect agent, Backend agent, Legal Expert agent

## Context

The CSV has one row per movement, with only a date (no time, no sequence id). Measured on the provided file:

- Rows of one lawsuit are **not contiguous** (438 breaks in 5,568 rows).
- Only **27 of 100** lawsuits are strictly in date-descending order in the file.
- **1,175** groups of movements share the same date.
- No duplicate full rows.

The court page shows movements newest first. A summary needs them oldest first. Re-running the import must not duplicate data.

## Decision

1. Store `movements.source_row` (1-based data-row index in the CSV).
2. Display order: `occurred_on DESC, source_row ASC`. Chronological order for the LLM: `occurred_on ASC, source_row DESC`. Rationale: the file tends to list newer rows first, so within a date a lower row is assumed newer. This is an assumption; if wrong it only affects the order of same-day items.
3. Import is idempotent: group by lawsuit; per lawsuit, in one transaction, upsert the lawsuit by `number`, delete its movements, bulk insert the new ones.
4. Summaries are keyed by `movements_digest` (hash of ordered date|title|content), so re-importing identical data keeps cached summaries valid.
5. Row-level errors are skipped and reported, not fatal.
6. Money is parsed with `BigDecimal` from pt-BR format; never `Float`.

## Alternatives considered

| Alternative | Why not |
|-------------|---------|
| Sort by date only | Same-day order becomes nondeterministic |
| Use database insertion id as order | Depends on import order, which is not guaranteed to match the file |
| Unique key on (lawsuit, date, title, content) with upsert | Same-day repeated movements with identical text would collide; needs `source_row` anyway |
| Truncate all tables before import | Destroys summaries and feedback |

## Consequences

- One extra integer column and a composite index.
- Deleting and reinserting movements changes their ids on each import; nothing references movement ids from other tables, so this is safe. If that changes, revisit this ADR.
- The tie-break assumption must be stated in the README or domain doc (it is, in [data-import](../domains/data-import.md)).
