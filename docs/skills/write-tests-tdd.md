---
name: write-tests-tdd
description: Red-Green-Refactor workflow for every code change - choose the test layer, write the failing test first, implement the minimum, refactor, and keep the 80% coverage gate green. Use for all backend and frontend changes.
---

# Skill: Write tests (TDD)

## Purpose
Every behavior is born from a failing test. The challenge requires at least 80% coverage; TDD makes that a by-product and makes the tests meaningful. Adapted from the Doity TDD skill (hybrid unit + E2E model), with RSpec, Vitest and Playwright.

## When to use
All production code changes. Hotfix: write the test that reproduces the bug first ([`start-bugfix`](start-bugfix.md)). Pure docs or config changes are exempt.

## 1. Choose the layer

| Behavior lives in | Layer | Tool | Location |
|-------------------|-------|------|----------|
| Pure Ruby logic (CNJ, money, classifier, prompt builder, validators) | Unit | RSpec | `backend/spec/lib`, `spec/services` |
| Service with DB | Service | RSpec | `backend/spec/services` |
| GraphQL operation, auth, throttling | Request | RSpec | `backend/spec/requests`, `spec/graphql` |
| LLM adapter HTTP behavior | Contract | RSpec + WebMock | `backend/spec/services/llm` |
| Pure TS helper | Unit | Vitest | `frontend/src/lib/*.test.ts` |
| React component / page | Component | Vitest + Testing Library + MSW | `frontend/src/**/*.test.tsx` |
| Whole flow across stack | E2E | Playwright | `frontend/e2e/` (one smoke) |

Rule of thumb: extract logic into pure code and test it at the cheapest layer. Use higher layers only for wiring.

## 2. Derive tests from requirements
Each acceptance criterion in the spec `requirements.md` (e.g. `R3.2`) becomes at least one test. Name tests by behavior and include the requirement ID in the description when helpful.

## 3. Red -> Green -> Refactor
1. **Red.** Write the test. Run it. It must fail **for the right reason** (missing behavior, not a typo). Capture the failure output.
2. **Green.** Write the smallest code that passes. Run the test.
3. **Refactor.** Clean up with tests green. Run the full suite for that side (backend or frontend).
4. Repeat per criterion.

## 4. Rules for good tests
- Independent and order-free (random order passes).
- Deterministic: freeze time (`travel_to`), no sleeps, no network, no real LLM.
- One reason to fail per test; assert behavior, not private methods.
- Prefer real objects and a real DB for ActiveRecord; mock only boundaries (HTTP, clock).
- Frontend: query by role/label/text; never by CSS class.
- Use factories/fixtures; keep the CSV fixture tiny and documented.

## 5. Commands
```bash
docker compose run --rm api bundle exec rspec                 # all backend + coverage gate
docker compose run --rm api bundle exec rspec spec/lib/cnj_number_spec.rb
docker compose run --rm web npm test -- --run                 # all frontend + thresholds
docker compose run --rm web npm run test:e2e                  # Playwright smoke
```

## 6. Coverage gate
- Backend: SimpleCov `minimum_coverage 80` (line) with branch coverage reported. Build fails below.
- Frontend: Vitest thresholds 80 (lines, functions, statements), 70 branches.
- Never lower a threshold or exclude files to pass. Allowed exclusions: generated code, `config/`, `db/`, `bin/`, GraphQL codegen output, `summaries:eval` task.

## 7. Done criteria
- [ ] Each acceptance criterion has a test that failed first.
- [ ] Edge cases listed in [`qa-engineer`](../agents/qa-engineer.md) for the area are covered.
- [ ] Suite and coverage gate green; linters clean.
- [ ] Tests run offline.

## Common mistakes
- A test that passes on the first run (it never proved anything). Break the code to see it fail.
- Mocking the unit under test.
- Testing the framework (Rails/Apollo) instead of our behavior.
- Chasing the percentage with assertion-free tests.
