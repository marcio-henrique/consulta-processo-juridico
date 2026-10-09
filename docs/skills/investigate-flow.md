---
name: investigate-flow
description: Trace how a behavior works end to end (UI -> GraphQL operation -> resolver -> service -> model/DB, or CSV -> importer -> tables) without changing code. Use before modifying existing behavior or when asked how something works.
---

# Skill: Investigate flow

## Purpose
Understand existing behavior and its side effects by reading code, with no edits. Adapted from the Doity "investigar-regra-ou-fluxo" skill (route -> controller -> model -> view) to this stack.

## When to use
- Before changing existing behavior.
- When asked "how does X work" or "where is Y implemented".
- To map the impact of a change before planning.

## Steps

### 1. Find the entry point
- UI: route in `frontend/src/App` (router) -> page -> component.
- API: the operation name in `frontend/src/graphql/*.graphql` -> `backend/app/graphql/{queries,mutations}`.
- Data: `lib/tasks/import.rake` -> `app/services/imports/*`.
Use text search for the operation name, type name or UI string.

### 2. Follow the call chain
For each hop note the file and method:
```
Page/Component -> operation -> Resolver/Mutation -> Service#call -> Model/Query -> table
                                                  -> Llm::Client (if summary)
```
Read each method completely, not only the signature.

### 3. Identify sensitive points
- Persistence: inserts, upserts, deletes, locks, transactions.
- Business rules: ordering, digest, cache key, validation, authorization.
- External calls: LLM provider, timeouts, retries.
- Security: authentication checks, throttling, cookie handling.
- Privacy: what text reaches the LLM and the logs.

### 4. Check tests and docs
Find the specs that cover the path and the domain docs that describe it. Note gaps and contradictions between code, tests and docs.

### 5. Report (descriptive only)
```markdown
## Flow: <name>
Entry points: <UI / operation / task>
Chain: <file:method -> file:method ...>
Data touched: <tables/columns>
External calls: <providers>
Sensitive points: <list>
Tests covering it: <files> | Gaps: <list>
Docs: <files> | Mismatches: <list>
```
Do not propose refactors in this report.

## Output
A structured report. No file changes.

## Common mistakes
- Stopping at the resolver and missing the service.
- Reporting what the docs say instead of what the code does.
- Editing code "while I am here".
