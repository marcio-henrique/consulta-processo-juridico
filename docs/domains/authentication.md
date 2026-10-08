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
- Throttling (`rack-attack`): sign-in 5 attempts/min per IP and per email; sign-up 10/hour per IP; `generateSummary` 10/min per user.
- Query depth limit 10, complexity limit set in the schema.

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

## 6. Frontend behavior

| Route | Rule |
|-------|------|
| `/login`, `/cadastro` | Public. If already signed in, redirect to `/`. |
| `/`, `/processos/:number` | Protected. Anonymous users go to `/login?next=<path>`; after sign in, return to `next`. |
| App shell | Shows the user email and a "Sair" button when signed in. |

The auth state comes from the `me` query on app start; the SPA never reads the cookie.

## 7. Summary feedback

| Rule | Detail |
|------|--------|
| One vote per user per summary | Unique `(summary_id, user_id)` |
| Changing the vote | Allowed; `rateSummary` upserts |
| Value | `helpful: true/false` |
| Visibility | The user sees their own vote (`Summary.myFeedback`); no public counts in the UI |
| Aggregation | `bin/rails feedback:report` prints helpful rate per `prompt_version` and `model`, to guide prompt tuning |
| Scope | Rating attaches to a specific summary row, so a new prompt version starts with a clean slate |

UI: two buttons "Útil" / "Não foi útil" with `aria-pressed`, a short thank-you message, and no modal.

## 8. Privacy

Stored user data: email and password digest. Session rows store user agent and IP for security review only. No analytics or third-party trackers.
