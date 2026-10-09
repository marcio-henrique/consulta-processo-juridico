# Pull request description template

Use the sections below. Keep the title under 70 characters, in English, Conventional Commit style (`feat: ...`).

## Context
<!-- Why: link the spec (.kiro/specs/NN-name) and the challenge requirement it satisfies. -->

## Description
<!-- What and how, at a high level. -->

## Code changes
<!-- Key files, new tables/migrations, GraphQL schema changes, new ENV variables. -->

## Changes outside the codebase
<!-- ENV vars, secrets to configure, data to import, Docker changes. Write "None" if there are none. -->

## Tests
- Layer(s): <!-- RSpec unit / request / GraphQL, Vitest, Playwright -->
- Red-first confirmed: <!-- yes/no -->
- Commands run: <!-- exact commands -->
- Backend coverage: <!-- e.g. 91.2% (gate 80%) -->
- Frontend coverage: <!-- e.g. 86% -->

## Checklist
- [ ] Tasks ticked in `.kiro/specs/NN-name/tasks.md`
- [ ] Docs updated (domain doc / ADR / README) or "not needed" explained
- [ ] No secrets, no real LLM calls in tests
- [ ] Schema change reflected in `docs/architecture.md`
- [ ] UI copy in pt-BR, everything else in English
- [ ] Commits are in English

## Additional information
<!-- Screenshots, risks, follow-ups. -->
