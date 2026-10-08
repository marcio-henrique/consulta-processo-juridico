# Tasks: Project foundation

Lead: DevOps / Release. Status: not started.

## 4-hour execution board (overrides the hour estimates below)

Schedule, gates and file ownership: [EXECUTION-PLAN-4H](../../../docs/plan/EXECUTION-PLAN-4H.md). Contracts: [docs/contracts](../../../docs/contracts/README.md).

| Task | Lane | ⏱ min | After | Gate |
|------|------|------:|-------|------|
| F-1 Rails scaffold | P | 12 | - | G0 |
| F-2 Repo hygiene (`.gitignore` and `.env.example` already done; add `.editorconfig`, `.dockerignore`) | P | 5 | - | G0 |
| F-3 Compose, Dockerfiles, entrypoint (`${API_PORT:-3000}`, `${WEB_PORT:-5173}`, db not published, non-root api, `.env` optional) | P | 20 | - | G0 |
| F-4 Backend test tooling and gate | P | 10 | F-1, F-3 | G0 |
| F-5 GraphQL endpoint skeleton | P | 10 | F-4 | G0 |
| F-6 Frontend scaffold incl. every dependency (Apollo, Router, MSW, Vitest, RTL, `eslint-plugin-jsx-a11y`, `vitest-axe`, Playwright, `@axe-core/playwright`, codegen) | F1 | 15 | - | G0 |
| F-7 Apollo client, proxy, codegen from `docs/contracts/schema.graphql` | F1 | 10 | F-6 | G0 |
| F-8 GitHub Actions CI | P | 15 | G0 | G2 |
| F-9 README run instructions | P | 10 | G2 | G3 |
| F-10 Contract stubs: migrations, models, GraphQL stubs, messages, Gemfile | B1 | 25 | G0 | G1 |
| F-11 Schema dump and contract check | B1 | 5 | F-10 | G1 |
| Q-1 Factories, `execute_graphql` helper, small CSV fixture | QA | 20 | draft in wave 0; run after G0 | G1 |
| Q-2 Classifier titles YAML | QA | 10 | - | G1 |

New tasks for parallel execution (F-10, F-11, Q-1, Q-2) are defined at the end of this file.
Task IDs are stable references (F-n). Tick `[x]` when done. Follow Red -> Green -> Refactor wherever code is involved.

- [ ] **F-1. Verify versions and scaffold the Rails API** (0.5 h)
  - Check current stable Rails, Ruby image and PostgreSQL versions; record them in the README tech table.
  - Run `rails new` inside a `ruby:3.3` container with the flags from design.md; commit the scaffold untouched first.
  - _Requirements: 3.1, 2.6_

- [ ] **F-2. Repository hygiene** (0.25 h)
  - `.gitignore`, `.env.example`, `.editorconfig`.
  - **Known conflict:** the existing `.gitignore` is a single line `data/`, which keeps the CSV out of git. Ask the owner (plan Q9). Recommended rule: `data/*` + `!data/lawsuits_movements.csv`. Do not change the file before the owner confirms; do not commit the CSV before then either.
  - _Requirements: 1.1, 1.2, 1.3, 1.5_

- [ ] **F-3. Docker Compose, Dockerfiles and entrypoint** (0.75 h)
  - **Pre-check:** run `docker compose version`. On the development machine (verified 2026-10-07) only the legacy `docker-compose` 1.29.2 is installed and the `docker compose` (v2) plugin is missing; v1 is known to misbehave with recent Docker engines. Ask the owner to install the Compose v2 plugin before this task. The project documents `docker compose` (v2) because that is what reviewers will have.
  - `db`, `api`, `web` services; healthchecks; volume `pgdata`; `./data` mounted read-only.
  - Entrypoint: wait for DB, `db:prepare`; leave a marked hook for the import (spec 02, task I-7).
  - Red: write the `GET /up` request spec first, then make it pass inside the container.
  - _Requirements: 2.1, 2.2, 2.3, 2.5, 2.6_

- [ ] **F-4. Backend test tooling and coverage gate** (0.5 h)
  - RSpec, FactoryBot, WebMock, SimpleCov (80 gate, branch coverage), RuboCop, brakeman, bundler-audit.
  - Red: spec proving WebMock blocks real HTTP; verify the gate fails when coverage is forced below 80.
  - _Requirements: 3.3, 3.4, 3.5_

- [ ] **F-5. GraphQL endpoint skeleton** (0.5 h)
  - Install `graphql-ruby`; JSON-only `POST /graphql`; empty schema with a `version` field; schema dump task and committed `backend/schema.graphql`.
  - Red: request specs for 200 / 405 / 415.
  - _Requirements: 3.1, 3.2_

- [ ] **F-6. Frontend scaffold and test tooling** (0.5 h)
  - Vite React TS strict; Vitest + Testing Library + MSW; ESLint + Prettier; coverage thresholds.
  - Red: `App` smoke test.
  - _Requirements: 4.1, 4.2, 4.3_

- [ ] **F-7. Apollo client, proxy and codegen** (0.25 h)
  - Apollo client with `uri: '/graphql'`, `credentials: 'same-origin'`; Vite proxy; codegen from `backend/schema.graphql`.
  - _Requirements: 4.4, 4.5, 2.4_

- [ ] **F-8. GitHub Actions CI** (0.5 h)
  - Jobs per design.md; schema drift check; secret scan step (e.g. `gitleaks` action or a grep-based script).
  - _Requirements: 5.1, 5.2, 5.3, 1.4_

- [ ] **F-9. README run instructions and AGENTS.md commands** (0.25 h)
  - Fill the "Getting started" section of the README; execute every command verbatim on a clean clone; fix mismatches in README and AGENTS.md.
  - _Requirements: 6.1, 6.2, 6.3_

## Definition of done (spec)
- [ ] `docker compose up --build` works on a clean clone and `GET /up` is 200.
- [ ] Backend and frontend suites green; both coverage gates verified to fail when violated.
- [ ] CI green on the default branch.
- [ ] README "Status" line updated; `backend/` and `frontend/` mentioned as existing in AGENTS.md.

## Tasks added for the 4-hour parallel plan

- [ ] **F-10. Contract stubs and migrations** · Lane B1 · ⏱ 25 · After: G0 (draft earlier) · Parallel: I-1, I-2, Q-1, A-*, F-*
  - Create the six migrations from [architecture](../../../docs/architecture.md) section 3 (indexes, foreign keys, unique constraints), model skeletons with associations only, `Errors::Messages` (pt-BR table in [contracts](../../../docs/contracts/README.md)), `Types::UserErrorType`, `Types::ErrorCode`, `Types::QueryType` and `Types::MutationType` with **every** field of `docs/contracts/schema.graphql`, each pointing to its own resolver/mutation class with a stub body, `Security::GraphqlLimits` (empty module, filled by SEC-3) included in the schema.
  - Collect Gemfile requests from the lane logs and finalize `Gemfile`.
  - Red: a spec that loads the schema and asserts every contract field exists; migration spec (`db:migrate` from empty, `db:rollback` works).
  - Files: `backend/db/migrate/**`, `backend/app/models/**` (skeletons), `backend/app/graphql/**` (stubs), `backend/app/services/errors/messages.rb`, `backend/Gemfile*`
  - _Requirements: 7.1, 7.2, 7.4, 7.6_

- [ ] **F-11. Schema dump and contract check** · Lane B1 · ⏱ 5 · After: F-10
  - Add `rake graphql:schema:dump` (writes `backend/schema.graphql`) and `backend/bin/contract_check` (compares with `docs/contracts/schema.graphql`, ignoring descriptions and order, prints differences, exit 1 on difference). Add both to CI via lane P.
  - Files: `backend/lib/tasks/graphql.rake`, `backend/bin/contract_check`, `backend/schema.graphql`
  - _Requirements: 7.3_

- [ ] **Q-1. Test support: factories, `execute_graphql`, CSV fixture** · Lane QA · ⏱ 20 · After: draft in wave 0 (attributes are in architecture.md); run after G0 · Merge at G1
  - `spec/support/graphql_helpers.rb`: `execute_graphql(query, variables: {}, user: :default)` calls `Schema.execute` with `context: { current_user: user }`; `:default` builds a factory user, `nil` is anonymous; returns parsed hash.
  - Factories for lawsuit, movement (with `source_row` sequence), summary, user, session, summary_feedback. A trait `:with_movements` creating N movements.
  - `spec/fixtures/files/lawsuits_small.csv` covering every case in [data-import](../../../docs/domains/data-import.md) section 8.
  - Files: `backend/spec/support/**`, `backend/spec/factories/**`, `backend/spec/fixtures/files/**`
  - _Requirements: 7.5_

- [ ] **Q-2. Classifier titles table** · Lane QA (with Legal Expert review) · ⏱ 10 · After: none
  - `backend/spec/fixtures/classifier_titles.yml`: at least 60 real titles from the CSV (all titles in the [legal glossary](../../../docs/domains/legal-glossary.md) tables plus 10 unknown ones) with `expected: milestone|context|noise`. Legal Expert checks every line.
  - Files: `backend/spec/fixtures/classifier_titles.yml`
  - _Requirements: 7.7_
