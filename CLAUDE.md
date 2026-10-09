# CLAUDE.md

Entry point for **Claude Code**. The canonical agent document is [`AGENTS.md`](AGENTS.md), imported below.
This file only adds what Claude Code does not load on its own and a few executable shortcuts.

@AGENTS.md

---

## Read on demand

| Situation | Read |
|-----------|------|
| New feature or spec task | `docs/skills/start-feature.md`, then the spec folder in `.kiro/specs/` |
| Any code change | `docs/AI-GUARDRAILS.md`, `docs/skills/write-tests-tdd.md` |
| Data model, GraphQL schema, boundaries | `docs/architecture.md`, `docs/adr/` |
| Importing the CSV | `docs/domains/data-import.md` |
| Prompt, model, summary quality | `docs/domains/ai-summary.md`, `docs/skills/tune-llm-summary.md`, `docs/domains/legal-glossary.md` |
| UI that mimics e-SAJ | `docs/domains/lawsuit-lookup.md`, `data/html_link_portal/` (saved reference page) |
| Login, sessions, feedback | `docs/domains/authentication.md` |
| Opening a PR | `docs/skills/create-pull-request.md` |
| Final submission | `docs/skills/prepare-delivery.md` |

## Role switching

To work as a specific role, read its file in `docs/agents/` first and say which role you adopted.
For reviews, prefer a different role than the one that wrote the code (e.g. Legal Expert reviews the summary prompt; QA reviews tests).

## TDD shortcut

- Backend: `docker compose run --rm api bundle exec rspec path/to/spec.rb` (Red), implement, rerun (Green), refactor.
- Frontend: `docker compose run --rm web npm test -- --run path/to/file.test.tsx`.
- Done means: suites green **and** coverage gate (>= 80%) green.

## Conventions

- Language: English everywhere (code, docs, commits, PRs). UI copy and LLM output for users are Portuguese (pt-BR).
- Never run the app against a real LLM in tests. Never commit `.env` or API keys.
- Ask before: force-push, rewriting history, deleting files in `data/`, changing the CSV import contract, adding a new runtime dependency.
