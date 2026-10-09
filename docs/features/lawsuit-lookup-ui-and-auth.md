# Feature: Lawsuit lookup UI and authentication

> React interface for the CNJ lookup (home, lawsuit page with summary and movements) behind email/password accounts. Specs 05 and 06; challenge items FR 2, 3, 4 (display), differentials 2 and 4.

## Context
Users type a CNJ number and read the lawsuit data, an AI summary and the court movements laid out like the TJSP e-SAJ page. Using the lookup requires an account (cookie session, [ADR-0004](../adr/0004-cookie-session-authentication.md)).

## Scope
Included: login, sign up, sign out, protected routes, home search with CNJ mask and validation, lawsuit page states (loading, not found, error), summary card, paged movements table, accessibility (WCAG 2.2 AA target), security hardening (headers, log filtering, GraphQL limits, throttling).
Out of scope: password reset, e-mail verification, MFA, rating the summary (spec 07).

## Flow
1. Anonymous visit of `/` or `/processos/:number` -> `/login?next=<path>`.
2. `/cadastro` or `/login` -> session cookie -> back to `next` (same-origin relative paths only).
3. Home: mask while typing, empty/invalid number -> inline `role="alert"` error and focus on the field; valid -> `/processos/<canonical>`.
4. Lawsuit page: header and data, summary (cached, or `generateSummary` once per lawsuit; error + retry), movements 25 at a time ("Carregar mais"), long content collapsed ("Ver mais").
5. Any `UNAUTHENTICATED` answer -> `/login?next=<current path>`. "Sair" -> `signOut`, Apollo cache cleared, plain `/login`.

## Main files
| Type | Path |
|------|------|
| Auth backend | `backend/app/services/auth/`, `backend/app/lib/auth/`, `backend/app/graphql/{guard.rb,mutations/}`, `backend/app/controllers/graphql_controller.rb` |
| Hardening | `backend/config/initializers/{rack_attack,security_headers,filter_parameter_logging}.rb`, `backend/app/graphql/security/` |
| UI | `frontend/src/{pages,components,auth,lib,styles}/` |
| Tests | `backend/spec/{requests,graphql,services/auth,models,lib/auth}/`, `frontend/src/**/*.test.tsx`, `frontend/playwright/lookup.spec.ts` |

## Business rules
1. Password 10 to 72 bytes, e-mail unique case-insensitively; sign-in failure message never reveals which part was wrong.
2. Only the SHA-256 digest of the session token is stored; cookie `HttpOnly; SameSite=Lax; Secure` (production), 14 days.
3. Every GraphQL root field except `signUp`, `signIn`, `me` answers `UNAUTHENTICATED` to anonymous callers without running (guard spec iterates the schema).
4. Summary text is rendered as text only, never HTML.

## Accessibility record (WCAG 2.2 AA)
- axe (vitest-axe per component/page state; `@axe-core/playwright` with tags `wcag2a`, `wcag2aa`, `wcag21aa`, `wcag22aa` on login, sign up with errors, lawsuit, not found): 0 serious/critical.
- Keyboard: skip link is the first tab stop; focus moves to the `h1` on every route change (tested); no traps.
- 320 px: no page-level horizontal scroll on the login page (Playwright); the lawsuit page was checked by screenshot at 360 px only, so a 320 px check of it remains manual. The movements table scrolls inside its own container.
- Reduced motion: skeleton shimmer and transitions are disabled under `prefers-reduced-motion`.
- Contrast ratios (computed from `styles/tokens.css`): text on surface 14.8:1, text on page 13.6:1, muted text 6.5:1 (5.8:1 on striped rows), link 7.5:1, white on brand 12.4:1, error text 6.5:1, input border 3.7:1, focus ring 6.4:1 (7.7:1 on the dark header).
- Not done by this work (needs a human with assistive technology): screen-reader walkthrough (NVDA/Orca/VoiceOver), 200% zoom visual check, text-spacing bookmarklet. Full conformance needs expert review; this record is a risk reduction, not a certification.

## Dependencies
`rack-attack` cache (in-process memory store), `rxjs` (peer of Apollo Client 4), GraphQL codegen output (`src/graphql/generated`, git-ignored; `npm run dev|test|typecheck|build` regenerate it).

## Notes
- The Vite proxy must keep the browser's `Host` header (`changeOrigin: false`), otherwise the API's Origin check answers 403.
- The throttle counters are per process; use a shared cache store if the API ever runs as several processes.
- Apollo is not cleared when `UNAUTHENTICATED` arrives mid-request (it would reject in-flight queries); it is cleared at the next sign in and at sign out.
