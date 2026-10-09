# ADR-0004: Cookie session authentication

- Status: Accepted
- Date: 2026-10-07
- Deciders: Project owner, Architect agent, Backend agent

## Context

Challenge differential 4 asks for user authentication to use the feature. Differential 5 (rating) needs a user identity. The SPA and API can be served from one origin. We want few dependencies and no token handling in JavaScript.

## Decision

1. Accounts: email + password with `has_secure_password` (bcrypt). No Devise.
2. Sessions: a `sessions` table. On sign-in, generate a 32-byte random token, store its SHA-256 digest, and set the raw token in an `HttpOnly; SameSite=Lax; Secure (prod)` cookie. Lifetime 14 days.
3. The GraphQL context loads the session from the cookie and exposes `current_user`.
4. Same-origin deployment: Vite dev server proxies `/graphql` to the API; production serves the built SPA behind the same host. No CORS.
5. CSRF mitigation: JSON-only POST, `Origin` check, `SameSite=Lax`.
6. Throttling with `rack-attack`: sign-in, sign-up and summary generation.
7. Generic sign-in error to avoid user enumeration.

Details and matrix: [authentication](../domains/authentication.md).

## Alternatives considered

| Alternative | Why not |
|-------------|---------|
| Devise + devise-jwt | Heavy; JWT revocation is awkward; more config than we need |
| JWT in `localStorage` | Exposed to XSS; needs manual refresh logic |
| Rails encrypted cookie session (no table) | Cannot revoke a session server-side |
| Rails 8 authentication generator output | Similar to this decision but session-view based; we adapt the same idea to GraphQL |
| OAuth/social login | Needs external setup; reviewers cannot test without credentials |

## Consequences

- Dev and prod need the same-origin setup; documented in the README.
- No password reset or email verification (out of scope; noted in the README).
- A short `sessions` cleanup happens lazily on read; no scheduler needed.
