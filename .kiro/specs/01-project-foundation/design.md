# Design: Project foundation

## Overview

Monorepo with `backend/` (Rails API) and `frontend/` (Vite React), orchestrated by Docker Compose. The host Ruby is 3.0.2, so **all Ruby commands run inside containers**, including scaffolding.

## Layout

```
.
├── backend/                 # Rails API
├── frontend/                # Vite React TS
├── data/                    # challenge input (read-only, mounted into api)
├── docker-compose.yml
├── .env.example
├── .github/workflows/ci.yml
├── .gitignore  .editorconfig
└── docs/  .kiro/  AGENTS.md  CLAUDE.md  README.md
```

## Docker Compose

| Service | Image / build | Ports | Notes |
|---------|---------------|-------|-------|
| `db` | `postgres:16` | internal 5432 | healthcheck `pg_isready`; volume `pgdata` |
| `api` | `backend/Dockerfile` (ruby 3.3) | 3000 | depends_on `db` healthy; mounts `./data:/data:ro`; entrypoint runs `db:prepare` and, if empty, the import (added by spec 02) |
| `web` | `frontend/Dockerfile` (node 22) | 5173 | Vite dev server; `VITE_API_PROXY_TARGET=http://api:3000` |

Environment is read from `.env` (copied from `.env.example`). Variables: `POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_DB`, `DATABASE_URL`, `SECRET_KEY_BASE`, `RAILS_ENV`, `LLM_PROVIDER` (default `auto`), `LLM_MODEL`, `LLM_FALLBACK_MODEL`, `GEMINI_API_KEY` (secret, comes from the git-ignored `.env`), `LLM_TIMEOUT_SECONDS`, `LAWSUITS_CSV_PATH` (default `/data/lawsuits_movements.csv`).

## Backend skeleton

- Created with `rails new backend --api --database=postgresql --skip-git --skip-action-mailer --skip-action-mailbox --skip-action-text --skip-active-storage --skip-action-cable --skip-jbuilder --skip-test` run inside a `ruby:3.3` container (flags verified against the installed Rails version in F-1).
- Gems: `graphql`, `rack-attack` (used later), `bcrypt` (used later), `faraday` (used later); dev/test: `rspec-rails`, `factory_bot_rails`, `webmock`, `simplecov`, `rubocop-rails-omakase` or project RuboCop config, `bundler-audit`, `brakeman`.
- `GraphqlController#execute` accepts only JSON POST. `Schema` has an empty `Query` placeholder (`version` field) until spec 03.
- `rake graphql:schema:dump` writes `backend/schema.graphql` (committed) and is used by frontend codegen. CI checks that the committed file is up to date.
- `spec/spec_helper.rb`: SimpleCov `enable_coverage :branch`, `minimum_coverage line: 80`, filters for `config/`, `db/`, `bin/`, `spec/`; `WebMock.disable_net_connect!(allow_localhost: false)`.

## Frontend skeleton

- `npm create vite@latest frontend -- --template react-ts`, then add: `react-router-dom`, `@apollo/client`, `graphql`, `vitest`, `@vitest/coverage-v8`, `@testing-library/react`, `@testing-library/user-event`, `@testing-library/jest-dom`, `msw`, `eslint` + TS/React plugins, `prettier`, `@graphql-codegen/cli` + `client-preset`.
- `vite.config.ts`: `server.proxy['/graphql']` to the API target; `test` block with jsdom, setup file, coverage thresholds.
- `codegen.ts`: schema from `../backend/schema.graphql`, documents from `src/**/*.graphql`, output `src/graphql/generated/`.
- Scripts: `dev`, `build`, `lint`, `typecheck`, `test`, `codegen`.

## CI (`.github/workflows/ci.yml`)

Jobs `backend` (ruby 3.3, postgres service: rubocop, brakeman, bundler-audit, rspec) and `frontend` (node 22: lint, typecheck, codegen drift check, test, build). `LLM_PROVIDER=fake`. Caches for bundler and npm.

## Error handling

Not applicable beyond: `/graphql` returns 415/405 for wrong content type/method; `/up` returns 503 if the DB is down.

## Testing strategy

- Request spec: `GET /up` 200.
- Request spec: `POST /graphql` JSON ok; `GET /graphql` 405; non-JSON 415.
- Spec that proves WebMock blocks real HTTP.
- Frontend: render smoke test of `App`; a unit test of the Apollo client config (uri `/graphql`, credentials `same-origin`).
- Gate verification: temporarily run with an unexecuted file to see the gate fail (manual, noted in PR).
