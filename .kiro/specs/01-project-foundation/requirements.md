# Requirements: Project foundation

## Introduction

Create the runnable skeleton of the project: repository hygiene, Docker Compose environment, Rails API, React app, test tooling with the 80% coverage gate, CI and the README run instructions. No product behavior yet. Challenge items: NFR 2 (coverage), NFR 3 (relational DB), NFR 4 (README), NFR 5 (AGENTS.md accuracy).

Roles: DevOps / Release (lead), Architect, QA. Related: [ADR-0001](../../../docs/adr/0001-technology-stack.md), [architecture](../../../docs/architecture.md).

## Requirements

### Requirement 1: Repository hygiene

**User Story:** As a maintainer, I want a clean repository that cannot leak secrets, so that the project can be shared safely.

#### Acceptance Criteria
1. THE repository SHALL contain a `.gitignore` that excludes `.env*` (except `.env.example`), `config/master.key`, `node_modules`, `tmp`, `log`, `coverage`, build output and editor files.
2. THE repository SHALL contain `.env.example` listing every ENV variable the stack reads, with placeholder values and no real secrets.
3. THE repository SHALL contain `.editorconfig` with UTF-8, LF and final newline.
4. WHEN a file matching a secret pattern is staged, THEN the CI secret scan step SHALL fail the build.
5. THE `.gitignore` SHALL NOT exclude `data/lawsuits_movements.csv`, so that a fresh clone contains the file the importer needs (owner decision Q9 in the implementation plan; the challenge statement and the saved e-SAJ page MAY stay untracked).

### Requirement 2: One-command environment

**User Story:** As a reviewer, I want to start everything with Docker, so that I do not install Ruby, Node or PostgreSQL.

#### Acceptance Criteria
1. WHEN `docker compose up --build` runs on a clean clone with `.env` copied from `.env.example`, THEN the system SHALL start `db` (PostgreSQL), `api` (Rails) and `web` (Vite) services.
2. THE `api` service SHALL wait for a healthy `db` before booting and SHALL run `db:prepare` on start.
3. THE `api` service SHALL expose `GET /up` returning HTTP 200 when the app and DB are reachable.
4. THE `web` service SHALL proxy `/graphql` to the `api` service so that browser and API share one origin.
5. THE database data SHALL persist in a named volume across restarts.
6. THE `api` image SHALL use Ruby 3.3 or newer, independent of the host Ruby version.

### Requirement 3: Backend skeleton and test tooling

**User Story:** As a developer, I want the Rails API ready with test tooling, so that I can start with Red tests.

#### Acceptance Criteria
1. THE backend SHALL be a Rails API-only app using PostgreSQL, with `graphql-ruby` installed and an empty schema served at `POST /graphql`.
2. THE `/graphql` endpoint SHALL accept only `POST` requests with `Content-Type: application/json`; other methods or content types SHALL receive HTTP 405 or 415.
3. THE backend SHALL include RSpec, FactoryBot, WebMock (network disabled by default), RuboCop and SimpleCov.
4. WHEN the RSpec suite finishes with line coverage below 80%, THEN the process SHALL exit with a non-zero status.
5. WHEN a test attempts a real outbound HTTP request, THEN WebMock SHALL raise an error.

### Requirement 4: Frontend skeleton and test tooling

**User Story:** As a developer, I want the React app ready with test tooling, so that I can build components test-first.

#### Acceptance Criteria
1. THE frontend SHALL be a Vite + React + TypeScript app with `strict: true`.
2. THE frontend SHALL include Vitest, Testing Library, MSW, ESLint, Prettier and Apollo Client.
3. WHEN `npm test -- --run` finishes with coverage below the thresholds (80 lines/functions/statements, 70 branches), THEN the process SHALL exit with a non-zero status.
4. THE frontend SHALL generate GraphQL types with GraphQL Code Generator from the backend schema file `backend/schema.graphql`.
5. THE Vite dev server SHALL proxy `/graphql` to the API.

### Requirement 5: Continuous integration

**User Story:** As a maintainer, I want automated checks, so that the coverage gate and lint cannot be bypassed.

#### Acceptance Criteria
1. WHEN a push or pull request happens, THEN GitHub Actions SHALL run RuboCop, RSpec with the coverage gate, the frontend lint, typecheck, tests with thresholds, and the frontend build.
2. THE CI SHALL run with `LLM_PROVIDER=fake` and no secrets.
3. IF any step fails, THEN the workflow SHALL fail.

### Requirement 6: README and AGENTS.md accuracy

**User Story:** As a reviewer, I want accurate run instructions, so that I can run the project quickly.

#### Acceptance Criteria
1. THE README SHALL document prerequisites, quick start, ENV variables, how to run tests with coverage, the technology list with reasons, and the project layout.
2. WHEN the commands in the README and in the AGENTS.md "Common commands" are executed verbatim on a clean clone, THEN they SHALL succeed.
3. THE README SHALL state known limits (only imported lawsuits are searchable; no password reset).

### Requirement 7: Contract stubs and shared test support

**User Story:** As a lane owner in a parallel team, I want every shared interface to exist from the start, so that I never edit a file owned by another lane.

#### Acceptance Criteria
1. THE backend SHALL have migrations for `lawsuits`, `movements`, `summaries`, `users`, `sessions` and `summary_feedbacks` exactly as in `docs/architecture.md`, and `db:migrate` from an empty database SHALL succeed.
2. THE backend SHALL define `Types::QueryType` and `Types::MutationType` with **every** field of `docs/contracts/schema.graphql`, each backed by its own resolver or mutation class (stub bodies allowed).
3. WHEN the schema is dumped, THEN a script (`backend/bin/contract_check`) SHALL compare it with `docs/contracts/schema.graphql` ignoring descriptions and field order and SHALL print every difference.
4. THE backend SHALL provide `Errors::Messages` with the pt-BR messages from `docs/contracts/README.md`.
5. THE backend test suite SHALL provide `execute_graphql(query, variables: {}, user: :default)` (runs the schema in-process; `user: nil` means anonymous), factories for every model, and the fixture `spec/fixtures/files/lawsuits_small.csv` covering the edge cases of `docs/domains/data-import.md` section 8.
6. THE `Gemfile` and the frontend `package.json` SHALL contain every dependency that any lane announced, so that no lane edits them afterwards.
7. THE repository SHALL provide a classifier title table `backend/spec/fixtures/classifier_titles.yml` with at least 60 real movement titles and their expected class.

### Requirement 8: Environment for parallel agents

**User Story:** As the integrator, I want several agents to run the stack at the same time on one machine without collisions.

#### Acceptance Criteria
1. THE Compose file SHALL not publish the database port, SHALL publish `api` and `web` on `${API_PORT:-3000}` and `${WEB_PORT:-5173}`, and SHALL work with any `COMPOSE_PROJECT_NAME`.
2. THE `.env` file SHALL be optional for Compose (missing file does not fail `config` or `run` for tests).
3. THE `api` image SHALL run as a non-root user.
4. THE frontend SHALL be runnable on the host with Node 22 (`npm ci`, `npm test -- --run`) as well as in the container.
