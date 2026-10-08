# Design: Lawsuit lookup UI

## Overview

Vite React TS SPA. Routes: `/` (home), `/processos/:number` (lawsuit). Apollo Client talks to `/graphql` (same origin). Typed operations come from GraphQL Code Generator.

## Structure

```
frontend/src/
  main.tsx  App.tsx  routes.tsx
  apollo/client.ts
  pages/HomePage.tsx  LawsuitPage.tsx
  components/
    AppShell.tsx  CnjSearchForm.tsx  LawsuitHeader.tsx  LawsuitData.tsx
    MovementsTable.tsx  MovementRow.tsx  SummaryCard.tsx  PageState.tsx
  graphql/
    lawsuit.graphql  generateSummary.graphql  generated/
  lib/cnj.ts  format.ts
  styles/  tokens.css  base.css  esaj.css
  test/  setup.ts  msw/handlers.ts  render.tsx
```

## Operations

```graphql
query Lawsuit($number: String!, $first: Int = 25, $after: String) {
  lawsuit(number: $number) {
    errors { code message field }
    lawsuit {
      number forum court numberOfAuthors movementsCount
      value { amount formatted }
      latestSummary { id body generatedAt }
      movements(first: $first, after: $after) {
        nodes { id date title content }
        pageInfo { hasNextPage endCursor }
      }
    }
  }
}

mutation GenerateSummary($lawsuitNumber: String!) {
  generateSummary(lawsuitNumber: $lawsuitNumber) {
    summary { id body generatedAt }
    errors { code message }
  }
}
```

`fetchMore` with a `merge` policy on `Lawsuit.movements` appends `nodes`.

## Components

| Component | Props | Behavior |
|-----------|-------|----------|
| `CnjSearchForm` | `onSubmit(number)` | Controlled input with mask via `cnj.maskInput`; validation on submit; errors via `role="alert"` |
| `HomePage` | - | Renders `CnjSearchForm`; on submit `navigate('/processos/' + canonical)` |
| `LawsuitPage` | - | Reads `:number`, runs the query, picks `PageState` or the content; triggers summary generation when `latestSummary` is null |
| `LawsuitHeader` | `number` | Large number + back link |
| `LawsuitData` | lawsuit | Definition list (Foro, Vara, Valor da ação, Número de autores) |
| `SummaryCard` | `summary`, `status`, `onRetry` | States: `ready`, `loading`, `error`; paragraphs split on `\n\n`; disclaimer; `aria-live` |
| `MovementsTable` | nodes, `hasMore`, `onLoadMore` | Table + "Carregar mais" |
| `MovementRow` | movement | Collapsible content (`Ver mais`/`Ver menos`) |
| `PageState` | kind | `loading`, `not-found`, `error` |

## Lib

```ts
// cnj.ts
export function digitsOnly(input: string): string
export function maskCnj(input: string): string          // progressive mask while typing
export function isValidCnj(input: string): boolean      // 20 digits + mod 97 check
export function formatCnj(digits: string): string
// format.ts
export function formatDate(iso: string): string         // '2023-12-05' -> '05/12/2023' (string ops, no Date)
```

Check digit in TS uses `BigInt` or chunked modulo to avoid precision loss on the 20-digit number.

## Summary flow

```
LawsuitPage loaded
  latestSummary present  -> SummaryCard(ready)
  latestSummary null     -> SummaryCard(loading); useEffect once: generateSummary
       success           -> write result into Apollo cache -> ready
       SUMMARY_UNAVAILABLE / RATE_LIMITED -> SummaryCard(error) with retry
```

Guard against double invocation (React StrictMode) with a ref keyed by lawsuit number.

## Styling

Plain CSS with tokens (`--color-muted`, `--color-border`, striped row color). e-SAJ-like blocks: section title with bottom rule, label/value pairs, striped table. Mobile: definition list stacks; table becomes horizontally contained inside its card (`overflow-x: auto`) only if needed.

## Error handling

`PageState` maps API error codes to copy. Apollo network errors map to the generic error. Never render `error.message` from the server or Apollo.

## Testing strategy

- `cnj.test.ts`, `format.test.ts`: tables, including the invalid example and the challenge example.
- `CnjSearchForm.test.tsx`: mask while typing, paste, empty, invalid, valid navigate, Enter submits, focus management.
- `MovementsTable.test.tsx`: caption/headers, order as given, collapse/expand with `aria-expanded`, line breaks, load more appends.
- `SummaryCard.test.tsx`: ready, loading (`aria-busy`), error + retry, paragraphs, disclaimer, no HTML injection (render `<img onerror>` text as text).
- `LawsuitPage.test.tsx` (MSW): found, loading, not found, network error, summary auto-generate once, retry flow.
- Manual a11y pass (keyboard, focus, zoom 200%) recorded in the PR; optional `vitest-axe` checks on key components.
