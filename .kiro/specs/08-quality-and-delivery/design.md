# Design: Quality and delivery

## Overview

No new product code. This spec adds the E2E smoke, the traceability table, security checks, final README and the delivery procedure.

## Coverage configuration (verification)

| Side | Tool | Config | Gate |
|------|------|--------|------|
| Backend | SimpleCov | `spec/spec_helper.rb`: `enable_coverage :branch`, `minimum_coverage line: 80`, filters `config/`, `db/`, `bin/`, `spec/`, `lib/tasks/summaries.rake` | exit != 0 below 80 |
| Frontend | Vitest + v8 | `vite.config.ts` `test.coverage.thresholds` {lines 80, functions 80, statements 80, branches 70}; exclude `src/graphql/generated`, `src/main.tsx`, `src/test` | exit != 0 below |

Both gates were created in spec 01; this spec verifies them with the full product code and records the numbers.

## E2E smoke (Playwright)

- Location: `frontend/e2e/smoke.spec.ts`, config `frontend/playwright.config.ts` with `baseURL` from `E2E_BASE_URL` (default `http://localhost:5173`).
- Runs against the Compose stack started with `LLM_PROVIDER=fake`. Unique email per run (`e2e+<timestamp>@example.com`).
- Compose profile `e2e` or a documented sequence: `docker compose up -d --build`, wait for `/up`, `npm run test:e2e`.
- Selectors by role and label only.
- CI: add a job only if total time < 10 minutes; otherwise keep manual and say so in the README.

## Traceability table (format)

Kept in `.kiro/specs/08-quality-and-delivery/traceability.md` (created in D-2).

| Challenge item | Spec requirement(s) | Evidence (test file or manual) |
|----------------|--------------------|--------------------------------|
| FR 1 | 02: 4.x, 6.1 | `spec/services/imports/lawsuits_csv_spec.rb`, `spec/integration/real_csv_import_spec.rb` |
| FR 2 | 05: 1.x | `CnjSearchForm.test.tsx` |
| ... | ... | ... |

## Security checks

| Check | Command (in containers) |
|-------|-------------------------|
| Static analysis (Rails) | `bundle exec brakeman -q` |
| Ruby dependencies | `bundle exec bundler-audit check --update` |
| JS dependencies | `npm audit --omit=dev` |
| Secrets in history | `gitleaks detect` (container) or `git log -p` grep for key patterns |
| Tracked env files | `git ls-files | grep -E '(^|/)\.env($|\.)' ` must list only `.env.example` |

## README final structure

1. Title, one-paragraph description, screenshots (home, lawsuit page, summary).
2. Features mapped to the challenge (required and differentials).
3. Stack and why.
4. Quick start (Docker), accounts, importing data.
5. ENV table and LLM configuration (fake vs real).
6. Tests and coverage (commands, numbers, exclusions).
7. Architecture in brief (link to docs).
8. Assumptions and limits (ordering tie-break, no password reset, only imported lawsuits, sync summary generation).
9. AI-assisted development: AGENTS.md, roles, skills, specs (short, with links).

## Delivery procedure

Follows [prepare-delivery](../../../docs/skills/prepare-delivery.md): requirements trace, clean-clone test, hygiene, sharing, video, email, freeze. The deadline is written at the top of the implementation plan as soon as the owner provides the email timestamp.

## Video outline (<= 4 min)

0:00-0:30 intro; 0:30-1:30 live demo; 1:30-2:30 architecture and summary pipeline; 2:30-3:20 quality (TDD, coverage, agents/skills); 3:20-4:00 decisions and next steps.

## Error handling

If any gate or check fails near the deadline, apply the cut-line from the implementation plan rather than lowering a gate.

## Testing strategy

This spec's own checks are the commands above plus a manual clean-clone run. Evidence (command outputs, numbers, screenshots) goes in the final PR description, not in the repository.
