# Domain: Authentication and feedback

> User accounts, sessions and summary ratings. Covers challenge differentials 4 and 5. Decision record: [ADR-0004](../adr/0004-cookie-session-authentication.md).

## 1. Scope

- Email + password sign up and sign in. No social login, no password reset, no email verification (documented as out of scope).
- Using the lookup (any lawsuit query, summary generation, rating) requires a signed-in user.
- Users can rate each summary as helpful or not helpful.

## 2. Accounts

| Rule | Value |
|------|-------|
| Email | Required, trimmed, lower-cased, valid format, unique (case-insensitive) |
| Password | Required, minimum 10 characters, maximum 72 bytes (bcrypt limit) |
| Storage | `password_digest` via `has_secure_password` (bcrypt) |
| Errors | Typed `UserError` with `field`; sign-in failure message is generic: "E-mail ou senha inválidos." (no user enumeration) |

## 3. Sessions

| Aspect | Decision |
|--------|----------|
| Mechanism | Server-side `sessions` table; opaque random token in a cookie |
| Token | 32 random bytes, URL-safe base64; only its SHA-256 digest is stored |
| Cookie | `_lawsuit_session`, `HttpOnly`, `SameSite=Lax`, `Secure` in production, `Path=/` |
| Lifetime | 14 days fixed; expired sessions are rejected and purged lazily |
| Sign out | Deletes the session row and clears the cookie |
| Revocation | Delete rows; changing password (future) would delete all of a user's sessions |

Same-origin deployment (Vite dev proxy in development) means no CORS and no third-party cookie issues.

## 4. Request protection

- GraphQL endpoint accepts only `POST` with `Content-Type: application/json`.
- `Origin` (when present) must match the request host; otherwise 403.
- `SameSite=Lax` blocks cross-site POST cookies.
- Throttling uses `rack-attack`'s cache and counters. The per-operation limits (sign-in 5/min per IP and per email, sign-up 10/hour per IP, `generateSummary` 10/min per user) are enforced where the operation runs (`Auth::Throttle`), so aliasing or batching mutations in one request cannot dodge them; the answer is a `RATE_LIMITED` user error. A coarse Rack-level throttle (300 requests per 5 minutes per IP on `/graphql`) answers HTTP 429 with a JSON body. The counters live in process memory, which is fine for the single-container demo.
- Every response carries `Content-Security-Policy`, `X-Content-Type-Options`, `Referrer-Policy: same-origin` and `X-Frame-Options: DENY` (plus HSTS in production). GraphQL: max depth 10, max complexity 200, at most 20 aliases of one field, introspection off in production.
- Logs filter `password`, `variables`, `query`, cookies, tokens and API keys.
- 
## 5. Authorization matrix

| Operation | Anonymous | Signed in |
|-----------|:---------:|:---------:|
| `signUp`, `signIn` | yes | yes (no-op or error) |
| `me` | yes (returns null) | yes |
| `lawsuit` | no | yes |
| `generateSummary` | no | yes |
| `rateSummary` | no | yes |
| `signOut` | no | yes |

Unauthenticated access to protected operations returns the `UNAUTHENTICATED` user error (HTTP 200, GraphQL convention), and the SPA redirects to `/login`.

Signing in or up while already signed in replaces the current session, so rows do not pile up.
## 6. Frontend behavior

| Route | Rule |
|-------|------|
| `/login`, `/cadastro` | Public. If already signed in, redirect to `/`. |
| `/`, `/processos/:number` | Protected. Anonymous users go to `/login?next=<path>`; after sign in, return to `next`. |
| App shell | Shows the user email and a "Sair" button when signed in. |

The auth state comes from the `me` query on app start; the SPA never reads the cookie and never writes credentials or tokens to web storage. The `?next=` target is accepted only when it is a same-origin relative path (`safeNext`). When any operation answers `UNAUTHENTICATED` (except `signIn`, where it means wrong credentials), the SPA drops its auth state and redirects to `/login?next=<current path>`. An explicit sign out clears the Apollo cache and goes to a plain `/login`.
There is no seeded account: create the first one at `/cadastro` (or with `signUp`).

## 7. Summary feedback

| Rule | Detail |
|------|--------|
| One vote per user per summary | Unique `(summary_id, user_id)` |
| Changing the vote | Allowed; `rateSummary` upserts |
| Value | `helpful: true/false` |
| Visibility | The user sees their own vote (`Summary.myFeedback`); no public counts in the UI |
| Aggregation | `bin/rails feedback:report` prints helpful rate per `prompt_version` and `model`, to guide prompt tuning |
| Scope | Rating attaches to a specific summary row, so a new prompt version starts with a clean slate |

Implementation: `Feedback::Rate` upserts on the unique index (concurrent clicks cannot raise or duplicate) and answers `NOT_FOUND` for an unknown summary; anonymous callers are stopped by the schema guard with `UNAUTHENTICATED`. `Summary.myFeedback` is batched by `Sources::MyFeedback`, keyed by the current user, so no query can return another user's vote. The foreign keys have no `on_delete: cascade`; `Summary` and `User` use `dependent: :destroy` for their votes instead.
Report: `docker compose run --rm api bin/rails feedback:report` prints one row per `prompt_version` and `model` (summaries, votes, helpful, not_helpful, helpful_rate) and "No feedback votes yet." when empty. It never prints user ids or emails.
UI: two buttons "Útil" / "Não foi útil" with `aria-pressed` (the pressed one is filled and gets a check mark), an optimistic update that Apollo rolls back on failure, and a polite live region with "Obrigado pelo feedback." or "Não foi possível registrar seu voto.". Clicking the active button keeps the vote and sends nothing. No modal. The buttons render only for a ready summary.

## 8. Privacy

Stored user data: email and password digest. Session rows store user agent and IP for security review only. No analytics or third-party trackers.
