# ADR-0001: Technology stack

- Status: Accepted
- Date: 2026-10-07
- Deciders: Project owner, Architect agent

## Context

The challenge allows any language, requires a relational database, >= 80% automated test coverage, a README and an AGENTS.md. It lists differentials: Ruby on Rails backend, React frontend, GraphQL API, user authentication, and a helpful/not helpful rating on the AI summary. The deadline is 48 hours, so the stack must be productive and every extra moving part must earn its place.

Host constraint: the development machine has Ruby 3.0.2 and Node 22; Docker is available. Current Rails releases need a newer Ruby than 3.0.

## Decision

| Layer | Choice | Reason |
|-------|--------|--------|
| Backend | Ruby on Rails (latest stable 8.x at implementation time), API mode | Challenge differential; fast to build; strong testing culture |
| API | GraphQL with `graphql-ruby` | Challenge differential; lets the SPA fetch lawsuit + movements + summary in one round trip |
| Database | PostgreSQL | Relational; JSON not needed; advisory locks for summary de-duplication |
| Frontend | React + TypeScript + Vite | Challenge differential; Vite gives a dev proxy for same-origin cookies |
| GraphQL client | Apollo Client | Mature cache; codegen for types via GraphQL Code Generator |
| Backend tests | RSpec, FactoryBot, WebMock, SimpleCov (gate 80%) | Rails standard |
| Frontend tests | Vitest, Testing Library, MSW | Fast, Vite-native |
| E2E | Playwright, one smoke flow | Proves the whole stack once, cheaply |
| Lint | RuboCop (rails-omakase or project config), ESLint + Prettier | Consistency |
| Runtime | Docker Compose: `db`, `api`, `web` | Reproducible; avoids the host Ruby version problem |
| CI | GitHub Actions | Repo is hosted on GitHub |

Ruby version: 3.3 in the Docker image (Rails 8 requires >= 3.2). Exact versions are pinned by `Gemfile.lock`, `package-lock.json` and the Docker image tag.

## Alternatives considered

| Alternative | Why not |
|-------------|---------|
| Rails monolith with server-rendered views | Loses the React and GraphQL differentials |
| REST instead of GraphQL | Loses a differential; no real savings with `graphql-ruby` |
| SQLite | Relational, but no advisory locks and a weaker match for production |
| Next.js full-stack | Not the Rails differential; splits the data layer |
| Redis + Sidekiq for summaries | Extra infra; see [ADR-0003](0003-synchronous-cached-summary.md) |
| urql instead of Apollo | Fine, but Apollo has more examples and codegen support in this stack |

## Consequences

- Two apps (`backend/`, `frontend/`) in one repo, orchestrated by Compose.
- Reviewers need only Docker to run everything.
- GraphQL adds schema discipline (complexity limits, N+1 control with `GraphQL::Dataloader`).
- Version numbers must be verified at bootstrap time (task F-1) and recorded in the README.
