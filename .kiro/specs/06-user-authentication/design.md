# Design: User authentication

## Overview

Rails `has_secure_password` + a `sessions` table + a signed-out-by-default GraphQL context. The cookie carries an opaque token; only its digest is stored ([ADR-0004](../../../docs/adr/0004-cookie-session-authentication.md)).

## Data model

```ruby
create_table :users do |t|
  t.string :email, null: false
  t.string :password_digest, null: false
  t.timestamps
end
add_index :users, "lower(email)", unique: true, name: "index_users_on_lower_email"

create_table :sessions do |t|
  t.references :user, null: false, foreign_key: { on_delete: :cascade }
  t.string   :token_digest, null: false
  t.string   :user_agent
  t.string   :ip_address
  t.datetime :expires_at, null: false
  t.timestamps
end
add_index :sessions, :token_digest, unique: true
```

## Backend components

| Component | Location | Responsibility |
|-----------|----------|----------------|
| `User` | `app/models/user.rb` | `has_secure_password`, email normalization/validation, password length rules |
| `Session` | `app/models/session.rb` | `active` scope, `expired?`, `Session.digest(token)` |
| `Auth::SessionToken` | `app/lib/auth/session_token.rb` | `generate -> [raw, digest]`, `digest(raw)`; uses `SecureRandom.urlsafe_base64(32)` and SHA-256 |
| `Auth::SignUp`, `Auth::SignIn`, `Auth::SignOut` | `app/services/auth/` | Return result objects; `SignIn` does a dummy `BCrypt` compare for unknown emails |
| `GraphqlController` | `app/controllers/graphql_controller.rb` | Reads cookie, loads `current_user` and `current_session`, builds context; sets/clears cookie after mutations via `context[:cookie_action]` |
| `Types::Mutations::SignUp/SignIn/SignOut`, `Query.me` | `app/graphql/` | Thin |
| Guard | `Types::BaseField` / `Schema.authorized?` or a field extension | Rejects anonymous calls for all fields except an allow-list (`signUp`, `signIn`, `me`) with `UNAUTHENTICATED` in `errors` |
| Request protection | `ApplicationController` before_action | Content-type, method, Origin host check |
| Throttles | `config/initializers/rack_attack.rb` | sign-in (IP, email), sign-up (IP) at Rack level; `generateSummary` per user at the service/mutation level using `Rails.cache` counters (memory store in test) |

Guard design note: for query fields returning payload types (`LawsuitPayload`), the guard returns `{ lawsuit: nil, errors: [UNAUTHENTICATED] }` instead of raising. Implement as a field extension that checks `context[:current_user]` and builds the typed payload through the field's `payload_factory`. Keep the allow-list explicit and tested.

Cookie handling: the controller writes `cookies[:_lawsuit_session] = { value:, httponly: true, same_site: :lax, secure: Rails.env.production?, expires: 14.days.from_now }`. In API-only mode, enable `ActionDispatch::Cookies` middleware.

## Frontend components

| Component | Responsibility |
|-----------|----------------|
| `auth/AuthProvider` | Runs `me` on start; exposes `{ user, status: 'loading' | 'anonymous' | 'authenticated', signIn, signUp, signOut }` |
| `auth/RequireAuth` | Redirects to `/login?next=` when anonymous; renders children when authenticated |
| `auth/safeNext` | Accepts only relative paths starting with `/` and not `//` |
| `pages/LoginPage`, `pages/SignUpPage` | Forms with inline errors from `UserError.field` |
| `AppShell` | Shows email + "Sair" |
| Apollo error link | On `UNAUTHENTICATED` in `errors`, resets auth state and redirects |

## GraphQL

```graphql
type User { id: ID!, email: String! }
type AuthPayload { user: User, errors: [UserError!]! }
input SignUpInput { email: String!, password: String! }
input SignInInput { email: String!, password: String! }
type SignOutPayload { success: Boolean!, errors: [UserError!]! }
extend type Query { me: User }
extend type Mutation { signUp(input: SignUpInput!): AuthPayload!  signIn(input: SignInInput!): AuthPayload!  signOut: SignOutPayload! }
```

## Error handling

| Case | Response |
|------|----------|
| Anonymous on protected op | `UNAUTHENTICATED` in `errors`, HTTP 200 |
| Bad credentials | `UNAUTHENTICATED`, "E-mail ou senha inválidos." |
| Validation errors | `VALIDATION_FAILED` + field |
| Rack throttle | HTTP 429 JSON `{ errors: [{ code: "RATE_LIMITED", message }] }`; the frontend maps 429 to a pt-BR message |
| Origin mismatch / wrong content type | 403 / 415 |

## Testing strategy

- `User`: normalization, uniqueness (case-insensitive), password length (9, 10, 72 bytes, 73 bytes, multibyte).
- `SessionToken`: length, uniqueness, digest differs from raw.
- Services and request specs: sign up/in/out happy paths; cookie flags (HttpOnly, SameSite, Secure in production env); wrong password vs unknown email same message; expired session rejected; signed-out cookie reuse rejected.
- Guard: every field except the allow-list rejects anonymous calls (iterate the schema fields to ensure no new field is unprotected by accident).
- Protection: GET -> 405, text/plain -> 415, foreign Origin -> 403.
- Throttling: sixth sign-in in a minute is limited; reset between examples (`Rack::Attack.cache.store.clear`).
- Frontend: `AuthProvider` states, `RequireAuth` redirect and `next` handling (including malicious `next=//evil.com`), login/sign-up forms and errors, sign out clears cache, UNAUTHENTICATED link.
