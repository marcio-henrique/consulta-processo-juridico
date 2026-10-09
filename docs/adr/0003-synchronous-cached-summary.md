# ADR-0003: Synchronous, cached summary generation

- Status: Accepted
- Date: 2026-10-07
- Deciders: Project owner, Architect agent, AI Engineer agent

## Context

An LLM call takes a few seconds and costs money. The lawsuit page must be usable immediately. The data set is small (100 lawsuits) and static between imports. A queue (Solid Queue, Sidekiq) adds a worker process, retries, polling and more failure modes.

## Decision

1. `Query.lawsuit` returns lawsuit data and movements without ever calling the LLM. `Lawsuit.latestSummary` returns a cached summary or null.
2. When `latestSummary` is null, the SPA renders the page and then calls the mutation `generateSummary(lawsuitNumber)`, showing a skeleton in the summary card only.
3. `generateSummary` runs **synchronously** in the request: cache lookup, prompt build, provider call (per-attempt timeout 20 s, up to 2 retries, then one fallback-model attempt, total deadline about 45 s; see ADR-0002), validation, persistence.
4. The cache key is `(lawsuit_id, movements_digest, prompt_version, model)` with a unique index.
5. Concurrent calls for the same key are serialized with `pg_advisory_xact_lock`; the second caller re-checks the cache and returns the first result.
6. Failures return `SUMMARY_UNAVAILABLE` as data; nothing is persisted; the UI offers a retry.
7. A per-user throttle (10 per minute) limits cost.

## Alternatives considered

| Alternative | Why not |
|-------------|---------|
| Generate all 100 summaries during import | Costs money up front; blocks the import on a key; stale when the prompt changes |
| Background job + polling | More infra and states for little gain at this scale |
| Make `lawsuit` query generate the summary | Slows the whole page; mixes read and write |
| Streaming (SSE/subscriptions) | Nice but out of proportion for 3 paragraphs |

## Consequences

- A cache miss holds one Puma thread for up to ~45 s in the worst case (typically 2-10 s); acceptable at this scale because of auth and throttling. Puma is configured with enough threads for demo use.
- Switching to a job-based flow later only changes the mutation internals and adds a status field; the cache key and schema stay.
- The first viewer of a lawsuit pays the latency; later viewers get it instantly.
