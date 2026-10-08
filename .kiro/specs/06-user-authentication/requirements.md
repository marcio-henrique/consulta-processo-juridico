# Requirements: User authentication

## Introduction

Email and password accounts with server-side cookie sessions. All lookup features require a signed-in user. Challenge item: differential 4. Related: [authentication](../../../docs/domains/authentication.md), [ADR-0004](../../../docs/adr/0004-cookie-session-authentication.md).

## Requirements

### Requirement 1: Sign up

**User Story:** As a visitor, I want to create an account, so that I can use the app.

#### Acceptance Criteria
1. WHEN `signUp` receives a valid email and a password of at least 10 characters (at most 72 bytes), THEN the system SHALL create the user, start a session, set the session cookie and return the user.
2. THE email SHALL be trimmed, lower-cased, validated for format and unique case-insensitively.
3. IF the email is taken, THEN the system SHALL return a `VALIDATION_FAILED` error with `field: "email"`.
4. IF the password is shorter than 10 characters or longer than 72 bytes, THEN the system SHALL return `VALIDATION_FAILED` with `field: "password"`.
5. THE system SHALL store only a bcrypt digest of the password.

### Requirement 2: Sign in and sign out

**User Story:** As a user, I want to sign in and out safely.

#### Acceptance Criteria
1. WHEN `signIn` receives matching credentials, THEN the system SHALL create a session, set the cookie and return the user.
2. IF the email is unknown or the password is wrong, THEN the system SHALL return the same error "E-mail ou senha inválidos." with code `UNAUTHENTICATED` and SHALL take comparable time (dummy digest compare for unknown emails).
3. WHEN `signOut` is called with a valid session, THEN the system SHALL delete the session row and clear the cookie.
4. WHEN a deleted or expired session cookie is presented, THEN the system SHALL treat the request as anonymous.

### Requirement 3: Session security

**User Story:** As an operator, I want sessions that are hard to steal or forge.

#### Acceptance Criteria
1. THE cookie `_lawsuit_session` SHALL be `HttpOnly`, `SameSite=Lax`, `Path=/`, and `Secure` in production.
2. THE cookie value SHALL be 32 random bytes encoded URL-safe; THE database SHALL store only its SHA-256 digest.
3. A session SHALL expire 14 days after creation; expired sessions SHALL be rejected.
4. THE system SHALL store user agent and IP on the session for audit only.

### Requirement 4: Authorization

**User Story:** As an owner, I want lookups to require an account.

#### Acceptance Criteria
1. EVERY GraphQL operation except `signUp`, `signIn` and `me` SHALL return `UNAUTHENTICATED` in `errors` for anonymous requests, without executing the operation.
2. THE `me` query SHALL return the current user or null.
3. EXISTING tests of specs 03 and 04 SHALL be updated to run as a signed-in user, plus tests that anonymous calls are rejected.

### Requirement 5: Request protection and throttling

**User Story:** As an operator, I want basic abuse protection.

#### Acceptance Criteria
1. THE `/graphql` endpoint SHALL accept only `POST` with `application/json`.
2. IF an `Origin` header is present and its host differs from the request host, THEN the system SHALL respond 403.
3. THE system SHALL throttle sign-in to 5 attempts per minute per IP and per email, sign-up to 10 per hour per IP, and `generateSummary` to 10 per minute per user.
4. WHEN a throttle is exceeded, THEN the system SHALL respond with a `RATE_LIMITED` user error (or HTTP 429 for the Rack-level throttles) and a pt-BR message.

### Requirement 6: Frontend authentication

**User Story:** As a user, I want a smooth login experience.

#### Acceptance Criteria
1. THE app SHALL provide `/login` and `/cadastro` pages with labeled fields, inline errors and pt-BR copy.
2. WHEN the app starts, THEN it SHALL call `me` to learn the auth state and show a loading state meanwhile.
3. WHEN an anonymous user opens a protected route, THEN the app SHALL redirect to `/login?next=<path>` and, after successful sign in, navigate to `next` (only same-origin relative paths are accepted).
4. WHEN a signed-in user opens `/login` or `/cadastro`, THEN the app SHALL redirect to `/`.
5. THE header SHALL show the user email and a "Sair" button; WHEN pressed, THE app SHALL call `signOut`, clear the Apollo cache and go to `/login`.
6. WHEN any operation returns `UNAUTHENTICATED`, THEN the app SHALL clear its auth state and redirect to `/login?next=<current path>`.
7. THE app SHALL NOT store tokens or credentials in `localStorage` or `sessionStorage`.

### Requirement 7: Security hardening

**User Story:** As an owner, I want secure defaults around the API, so that common web attacks and cost abuse are blocked. See [security](../../../docs/security.md).

#### Acceptance Criteria
1. EVERY response from the API SHALL carry `Content-Security-Policy` (`default-src 'self'`, `script-src 'self'`, `object-src 'none'`, `frame-ancestors 'none'`, `base-uri 'self'`), `X-Content-Type-Options: nosniff` and `Referrer-Policy: same-origin`; in production it SHALL also carry `Strict-Transport-Security`.
2. THE logs SHALL NOT contain passwords, GraphQL variables, cookies, authorization headers, the Gemini key, prompts or movement contents.
3. THE schema SHALL reject queries deeper than 10, queries with more than 20 aliases of one field, queries above the complexity cap and `first` above 100; introspection SHALL be disabled in production; errors SHALL be generic.
4. THE containers SHALL run as non-root, the images SHALL NOT contain `.env` or secrets, and the database port SHALL NOT be published.
