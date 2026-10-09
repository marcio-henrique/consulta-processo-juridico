# Tasks: User authentication

Lead: Backend (B3) + Frontend (F2) + Security (SEC). Status: done.

## 4-hour execution board (overrides the hour estimates below)

Schedule and ownership: [EXECUTION-PLAN-4H](../../../docs/plan/EXECUTION-PLAN-4H.md). Auth work does **not** wait for the core flow: tests use `execute_graphql(..., user:)` from Q-1, so B3 works in parallel with B1/B2/AI from G1.

| Task | Lane | ⏱ min | After | Review |
|------|------|------:|-------|--------|
| AU-2 `Auth::SessionToken` | B3 | 6 | G0 (draft earlier) | - |
| AU-1 `users`, `sessions` models (migrations are in F-10) | B3 | 8 | F-10 | - |
| AU-3 Sign up/in/out services, mutations, `me`, cookie | B3 | 25 | AU-1, AU-2 | SEC |
| AU-4 Context and authorization guard (allow-list) | B3 | 15 | AU-3 | SEC |
| AU-5 Request protection (JSON-only, Origin check) | B3 | 8 | AU-3 | SEC |
| AU-6 Throttling with rack-attack | B3 | 12 | AU-3 | SEC |
| AU-10 Update existing specs for the guard, docs | B3 | 5 | AU-4 | - |
| AU-7 Frontend auth context, login and sign-up pages | F2 | 20 | U-9a (MSW) | SEC, accessibility checklist |
| AU-8 Protected routes, `next` redirect, `UNAUTHENTICATED` handling | F2 | 15 | AU-7 | SEC |
| AU-9 App shell user menu and sign out | F2 | 5 | AU-7 | - |
| SEC-1 Security headers and CSP | SEC | 15 | G0 | - |
| SEC-2 Log filtering and key hygiene | SEC | 12 | G0 | - |
| SEC-3 GraphQL hardening: depth, aliases, complexity, introspection off in production | SEC | 12 | F-10 | - |
| SEC-4 Docker hardening | SEC | 10 | F-3 | - |

### Security hardening tasks (new)

- [x] **SEC-1. Security headers and CSP** · Lane SEC · ⏱ 15
  - Red: request spec asserting `Content-Security-Policy` (`default-src 'self'; script-src 'self'; object-src 'none'; frame-ancestors 'none'; base-uri 'self'`), `X-Content-Type-Options: nosniff`, `Referrer-Policy: same-origin`, HSTS in production, on `/graphql` and `/up`. Note for the dev server: Vite HMR needs a looser dev CSP; enforce the strict one in production builds and test it with a production-like run.
  - Files: `backend/config/initializers/security_headers.rb`
  - _Requirements: 7.1_
- [x] **SEC-2. Log filtering and key hygiene** · Lane SEC · ⏱ 12
  - Red: spec that triggers a sign-in with a password and a Gemini failure with a fake key, captures the log, and asserts neither the password, GraphQL variables, cookies nor the key appear. Configure `filter_parameters` as in [security.md](../../../docs/security.md) section 4.
  - Files: `backend/config/initializers/filter_parameter_logging.rb`
  - _Requirements: 7.2_
- [x] **SEC-3. GraphQL hardening** · Lane SEC · ⏱ 12
  - Red: specs for depth > 10, alias flood (more than 20 aliases of the same field), complexity cap, `first` > 100, introspection disabled in production, generic error body.
  - Files: `backend/app/graphql/security/graphql_limits.rb`
  - _Requirements: 7.3_
- [x] **SEC-4. Docker hardening** · Lane SEC (PR to P) · ⏱ 10
  - Checks: non-root user, `.dockerignore` excludes `.env`, `.git`, `node_modules`, no secrets in image layers, DB port not published. Add commands to [security-review](../../../docs/skills/security-review.md) output.
  - Files: `backend/Dockerfile`, `frontend/Dockerfile`, `.dockerignore`, `docker-compose.yml` (edits via PR reviewed by P)
  - _Requirements: 7.4_

- [x] **AU-1. `users` and `sessions` migrations and models** (0.5 h)
  - Red: model specs (email normalization, case-insensitive uniqueness, password 9/10/72/73 bytes, session expiry scope).
  - _Requirements: 1.2, 1.4, 1.5, 3.3_

- [x] **AU-2. `Auth::SessionToken`** (0.5 h)
  - Red: 32-byte URL-safe token, SHA-256 digest, raw never stored.
  - _Requirements: 3.2_

- [x] **AU-3. Sign up, sign in, sign out services and mutations; `me`** (1.0 h)
  - Red: request specs (cookie set with correct flags, generic failure message, constant-time dummy compare, sign out deletes the row and clears the cookie, expired/deleted sessions are anonymous).
  - _Requirements: 1.1, 1.3, 2.1, 2.2, 2.3, 2.4, 3.1, 3.4, 4.2_

- [x] **AU-4. GraphQL context and authorization guard** (0.5 h)
  - Red: schema-wide spec iterating fields; anonymous calls to `lawsuit`, `generateSummary` return `UNAUTHENTICATED` without executing.
  - _Requirements: 4.1_

- [x] **AU-5. Request protection** (0.25 h)
  - JSON-only POST (already from F-5, extend with tests), Origin host check, 403/415/405 specs.
  - _Requirements: 5.1, 5.2_

- [x] **AU-6. Throttling with rack-attack** (0.5 h)
  - Sign-in (IP and email), sign-up (IP), `generateSummary` per user; pt-BR messages; test cache cleanup.
  - _Requirements: 5.3, 5.4_

- [x] **AU-7. Frontend auth context and pages** (0.75 h)
  - Red: `AuthProvider` states; login and sign-up forms with field errors; no storage of credentials.
  - _Requirements: 6.1, 6.2, 6.7_

- [x] **AU-8. Protected routes, `next` redirect, UNAUTHENTICATED handling** (0.5 h)
  - Red: `RequireAuth`, `safeNext` (reject `//evil.com`, absolute URLs), signed-in visit to `/login` redirects, error link redirect.
  - _Requirements: 6.3, 6.4, 6.6_

- [x] **AU-9. App shell user menu and sign out** (0.25 h)
  - Red: shows email, "Sair" calls `signOut`, clears Apollo cache, goes to `/login`.
  - _Requirements: 6.5_

- [x] **AU-10. Update existing tests and docs** (0.25 h)
  - Add `sign_in_as(user)` helper; update specs from 03/04; MSW handlers for auth; update [authentication](../../../docs/domains/authentication.md), README (how to create the first account), `architecture.md`; run [finish-delivery-docs](../../../docs/skills/finish-delivery-docs.md).
  - _Requirements: 4.3_

## Definition of done (spec)
- [x] In the browser: anonymous visit to `/` redirects to login; sign up; land on home; search works; sign out returns to login.
- [x] Cookie is HttpOnly and SameSite=Lax (checked in dev tools).
- [x] No GraphQL field outside the allow-list is reachable anonymously (guard spec green).
- [x] Gate green on both sides.
