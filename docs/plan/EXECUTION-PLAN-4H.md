# Execution plan: 4 hours, parallel agents

> Owner decision (2026-10-08): **development must be finished in 4 hours**, with agents working simultaneously. This plan replaces the schedule in sections 5-6 of [IMPLEMENTATION-PLAN](IMPLEMENTATION-PLAN.md). Task definitions stay in the specs (`.kiro/specs/*/tasks.md`); here we only say **who does what, when, in which files, and when the lanes meet**.

## 1. Honest feasibility note

The earlier estimate was 36.5 focused hours for one AI-assisted person. In this plan the same scope is cut into **time-boxes in minutes** (about 17-18 agent-hours in total, spread over 9 lanes). That only works if:

1. agents are about twice as fast as the old estimates (typical for scoped, test-first tasks with clear contracts);
2. lanes never wait on each other: contracts, stubs and fixtures are created first (section 4) and file ownership prevents merge conflicts (section 5);
3. the owner does not become the bottleneck: the Integrator merges on green, the owner reviews asynchronously.

If the lanes run slower than the time-boxes, the **cut line** (section 8) triggers automatically at the gates. Quality gates (TDD, coverage 80%) are never cut.

"Development finished" means: code freeze at T+3:40, clean-clone verification done at T+4:00. The demo video and the email are human steps right after (about 30 minutes) and still fit the original 48-hour challenge deadline.

T0 = the moment the first lane starts. All times below are relative to T0.

## 2. Lanes (one agent session each)

| Lane | Role file | Specs / task IDs owned |
|------|-----------|------------------------|
| **P** Platform / Integrator | [devops-release-engineer](../agents/devops-release-engineer.md) | F-1, F-2, F-3, F-4, F-5, F-8, F-9, D-6, D-9; merges lanes into `main` |
| **B1** Contract and Lookup | [backend-engineer](../agents/backend-engineer.md) | F-10, F-11, I-3, L-1..L-5 |
| **B2** Import and Pipeline QA | [backend-engineer](../agents/backend-engineer.md) | I-1, I-2, I-4..I-9, A-13 |
| **B3** Auth and Feedback | [backend-engineer](../agents/backend-engineer.md) | AU-1..AU-6, AU-10, FB-1..FB-3, FB-5 |
| **AI** Summary pipeline | [ai-engineer](../agents/ai-engineer.md) | A-1..A-12 |
| **F1** Frontend core | [frontend-engineer](../agents/frontend-engineer.md) | F-6, F-7, U-1..U-6, U-8, U-12 |
| **F2** Frontend UX and accessibility | [frontend-engineer](../agents/frontend-engineer.md) | U-7, U-9, U-9a, U-10, U-11, AU-7, AU-8, AU-9, FB-4 |
| **SEC** Security | [security-engineer](../agents/security-engineer.md) | SEC-1..SEC-4, D-5, reviews |
| **QA** QA and Legal review | [qa-engineer](../agents/qa-engineer.md) + [legal-expert](../agents/legal-expert.md) | Q-1, Q-2, D-1..D-4, D-4a, D-7, reviews |

Architect duties (contract changes, design reviews, ADRs) are done by the Integrator lane on request, or by the owner.

**If fewer agents are available**, merge lanes in this order and extend the time-boxes by roughly 30%: B1+B2, F1+F2, SEC+QA (6 lanes), then B3 into B1/B2 (5 lanes). Apply the cut line earlier.

## 3. Timeline

```
T+0:00  Wave 0  All lanes start. Platform builds the runnable base; others draft against contracts.
T+0:30  G0      Runnable base merged (backend container, rspec, /up, JSON-only /graphql; frontend scaffold)
T+0:55  G1      Contract stubs merged (migrations, models, GraphQL stubs, helpers, factories, fixtures)
T+1:50  G2      Components done: import, lookup API, LLM pipeline parts, auth core, frontend against mocks
T+2:45  G3      Integrated end to end (real API + fake provider + Gemini), core complete
T+3:25  G4      Quality: coverage, E2E, accessibility, security, legal review
T+3:40  G5      CODE FREEZE
T+4:00  DONE    Clean-clone verification passed. Then video + email (human).
```

### Per-lane schedule (minutes are time-boxes; see each task in the specs)

| Lane | 0:00-0:30 (wave 0) | 0:30-0:55 | 0:55-1:50 | 1:50-2:45 | 2:45-3:25 | 3:25-4:00 |
|------|--------------------|-----------|-----------|-----------|-----------|-----------|
| **P** | F-3 compose + Dockerfile (20), F-1 Rails scaffold (15), F-4 tooling (10), F-5 endpoint (10) -> **G0** | F-2 (5), merge F-10 PR | F-8 CI (15), merge lane PRs | merge, fix integration breaks, F-9 README (10) | D-6 final README (15), D-9 prep | D-7 support, freeze |
| **B1** | Draft F-10 stubs from [contracts](../contracts/README.md) | **F-10** (25) -> **G1**, F-11 (5) | I-3 (8), L-1 (10), L-2 (10), L-3 (15), L-4 (8), L-5 (4) -> G2 | Help integrate GraphQL wiring, N+1 tuning | Bug fixing from E2E | - |
| **B2** | Draft I-1, I-2 (pure Ruby + specs) | Run/finish I-1 (10), I-2 (8) | I-4 (15), I-5 (12), I-6 (6), I-7 (6), I-8 (5), I-9 (5) -> G2 | A-13 pipeline over 100 lawsuits (20); coverage gaps | Coverage gaps (D-1 support) | - |
| **B3** | Draft AU-2 SessionToken | AU-2 (6) | AU-1 (8), AU-3 (25), AU-4 guard (15), AU-5 (8), AU-6 (12) | FB-1 (6), FB-2 (12), FB-3 (6), FB-5 (8), AU-10 (5) | Bug fixing | - |
| **AI** | Draft A-3/A-4 against Q-2 title table; A-1 RetryPolicy | A-1 (10), A-2 (15) | A-3 (12), A-4 (12), A-5 (20), A-6 (10), A-7 Gemini adapter (20) -> G2 | A-8 (5), A-9 Generate (25), A-10 GraphQL (12), A-11 eval (15) -> G3 | A-11 golden-set run, prompt fixes (bump version), A-12 (5) | - |
| **F1** | F-6 scaffold (15), F-7 Apollo + proxy + codegen (10) -> before G0 | U-1 (8), U-2 (4), U-3 (12) | U-4 (12), U-5 (10), U-6 (20), U-8 (15) -> G2 | U-12 switch to real API (15), bug fixing | E2E fixes | - |
| **F2** | U-9a tokens, base CSS, AppShell, SkipLink (20) | U-7 SummaryCard (15) | AU-7 (20), AU-8 (15), AU-9 (5), FB-4 (10) | U-9 e-SAJ styling (25), U-10 a11y pass (20) | U-11 coverage (10), a11y fixes | - |
| **SEC** | Review plan; draft header/log/limit specs | SEC-4 Docker hardening (10) after F-3 | SEC-1 headers (15), SEC-2 logging + key hygiene (12), SEC-3 GraphQL limits (12); review AU-3/AU-4 | Review Gemini adapter, importer | D-5 audit (20) -> G4 | - |
| **QA** | Q-1 factories + helpers + CSV fixture (20), Q-2 classifier titles YAML (10) | Deliver Q-1/Q-2 PR (merged at G1) | Legal: review classifier table + glossary (10), prompt (10); cross-review tests; D-2 draft (20) | Write E2E + axe specs (30) | D-1 (10), D-3 run (15), D-4 golden-set legal review (20), D-4a a11y audit (20) -> G4 | D-7 clean-clone (20) |

## 4. Contract-first rules (what makes the parallelism safe)

All shared interfaces are fixed **before** coding, in [`docs/contracts/`](../contracts/README.md):

1. [`schema.graphql`](../contracts/schema.graphql): full GraphQL contract. Frontend generates types and MSW mocks from it from minute 0. Backend implements it exactly.
2. Error codes and pt-BR messages, CNJ/money/date vectors, the known lawsuit and its newest movements, shortest/longest lawsuits, the golden set, and the Fake summary shape.
3. **Stubs first**: B1 creates every migration, model skeleton and GraphQL stub (task F-10) so that no other lane edits shared files afterwards.
4. **Test helpers first**: QA delivers `execute_graphql(query, variables:, user:)` (calls the schema in-process with `context[:current_user]`, default = a factory user, `user: nil` = anonymous), factories and the small CSV fixture (task Q-1). Lanes never depend on cookies or on the auth implementation to test their own work.
5. **Frontend uses MSW** until U-12; backend uses the Fake LLM provider until A-7/A-11.
6. The AI pipeline works on plain value objects (`date`, `title`, `content`, `source_row`), so it can be built and tested before the importer or models exist.

## 5. File ownership (no two lanes edit the same file)

| Path | Owner |
|------|-------|
| `docker-compose.yml`, `*/Dockerfile`, `.dockerignore`, `.editorconfig`, `.github/**`, `backend/Gemfile*` (after F-10 only B1), `README.md` | P |
| `backend/Gemfile`, `Gemfile.lock` | P at G0; **B1 at G1 adds every gem the other lanes announced**; afterwards ask B1 |
| `backend/db/migrate/**`, `backend/app/models/{lawsuit,movement}.rb`, `app/graphql/schema.rb`, `app/graphql/types/{query_type,mutation_type,base_*,lawsuit_type,movement_type,money_type,user_error_type,error_code}.rb`, `app/graphql/resolvers/lawsuit_resolver.rb`, `app/lib/money_formatter.rb`, `app/services/lawsuits/**`, `app/services/errors/messages.rb` | B1 |
| `backend/app/lib/{cnj_number,brl_parser}.rb`, `app/services/imports/**`, `lib/tasks/import.rake`, `db/seeds.rb` | B2 |
| `backend/app/models/{user,session,summary_feedback}.rb`, `app/services/auth/**`, `app/lib/auth/**`, `app/controllers/graphql_controller.rb` (from G0), `app/graphql/{guard,resolvers/me_resolver,mutations/{sign_up,sign_in,sign_out,rate_summary}}.rb`, `config/initializers/rack_attack.rb`, `lib/tasks/feedback.rake` | B3 |
| `backend/app/models/summary.rb`, `app/services/{llm,movements,summaries}/**`, `app/graphql/types/{summary_type,summary_feedback_type}.rb` (summary_feedback_type: B3), `app/graphql/mutations/generate_summary.rb`, `lib/tasks/summaries.rake` | AI |
| `backend/config/initializers/{security_headers,filter_parameter_logging}.rb`, `app/graphql/security/graphql_limits.rb`, Docker hardening edits (via PR to P) | SEC |
| `backend/spec/{support,factories,fixtures}/**` (shared), each lane owns the spec files for its own code | QA for shared; lanes for their specs |
| `frontend/package.json`, `vite.config.ts`, `tsconfig*`, eslint/prettier config, `codegen.ts`, `src/main.tsx`, `App.tsx`, `routes.tsx`, `apollo/**`, `graphql/*.graphql`, `lib/**`, `pages/{HomePage,LawsuitPage}.tsx`, `components/{CnjSearchForm,LawsuitHeader,LawsuitData,MovementsTable,MovementRow,PageState}.tsx`, `test/**` | F1 |
| `frontend/src/styles/**`, `components/{AppShell,SkipLink,SummaryCard,FeedbackButtons}.tsx`, `auth/**`, `pages/{LoginPage,SignUpPage}.tsx` | F2 |
| `frontend/e2e/**`, `playwright.config.ts`, `.kiro/specs/08-quality-and-delivery/traceability.md` | QA |
| `docs/security.md` status columns | SEC |
| `docs/**`, `.kiro/specs/**/tasks.md` checkboxes | each lane ticks only its own tasks (one-line edits; merge conflicts are trivial) |

Rule: if you need a change in a file you do not own, write a request in your lane log (section 7) addressed to the owner with the exact change; keep working on something else.

## 6. Working agreement

1. **Worktree per lane** (from the repository root):
   ```bash
   git worktree add ../wt-<lane> -b lane/<lane> main
   cd ../wt-<lane>
   export COMPOSE_PROJECT_NAME=lawsuits-<lane>      # isolates containers, networks and DB volume per lane
   ```
2. **Ports:** only `db` stays internal. `api` and `web` publish `${API_PORT:-3000}` and `${WEB_PORT:-5173}`; give each lane that runs a browser a distinct pair (for example F2: 3100/5273, QA: 3200/5373).
3. **Secrets:** `.env` is git-ignored, so a worktree has none. Copy it (`cp ../consulta-processo-juridico/.env .env`) **only** in lanes that need Gemini: AI and QA. All other lanes run with `LLM_PROVIDER=fake`. Never paste the key in chat, logs or files.
4. **Frontend speed:** frontend lanes may run npm directly on the host (Node 22) for speed; Compose is the reference environment and what CI and the clean-clone check use.
5. **TDD:** Red first, commit pairs `test: ...` then `feat: ...` ([write-tests-tdd](../skills/write-tests-tdd.md)). Run only your own specs while working; the full suite before opening a PR.
6. **Integration:** the lane rebases on `main`, runs its suite, opens a PR. P merges when green (fast-forward preferred), `main` is always green. P posts each gate in the execution log. The owner reviews after merge, not before, except for security-sensitive PRs flagged `needs-sec-review` (auth, guard, Gemini adapter, Docker).
7. **Commits:** English, Conventional Commits, small. No force-push to `main`.
8. **Accessibility and security notes** go in every UI/auth PR description (templates in the skills).
9. **Blocked for more than 10 minutes?** Write the blocker in the lane log, switch to the next unblocked task or to a draft of a later task, never idle.

## 7. Execution log

One file per lane in `docs/plan/log/<lane>.md` (append-only, one line per event: gate reached, task done, blocker, contract-change request). See [log README](log/README.md). P reads all lane logs at every gate.

## 8. Gates and cut line

| Gate | Time | Pass condition | Slip rule |
|------|------|----------------|-----------|
| **G0** | 0:30 | `docker compose run --rm api bundle exec rspec` runs green with SimpleCov gate; `GET /up` is 200; `POST /graphql` JSON-only; `frontend` scaffold builds and tests run | If late by 15 min: B/AI lanes continue drafts; no cut yet |
| **G1** | 0:55 | Contract stubs, migrations, helpers, factories, fixture merged; `backend/schema.graphql` dumped and diffed against the contract | If late by 15 min: B1 cuts L-5 doc time and I-3 polish |
| **G2** | 1:50 | Import done (100 / 5,568 / 0 skipped); `lawsuit` query live with tests; classifier/cleaner/prompt/validator/Gemini adapter merged; auth services merged; frontend home + lawsuit page against MSW | **If any lane is behind by more than 20 min: cut spec 07 (feedback) now** |
| **G3** | 2:45 | Whole flow works with real API: sign up, search, data, movements, summary (fake and Gemini), sign out; guard active; feedback works (if not cut) | **If not reached by 3:00: cut feedback; if not reached by 3:15: cut throttling except sign-in and freeze the rest to bug fixing** |
| **G4** | 3:25 | Coverage gates pass on both sides; E2E + axe zero serious/critical; security audit has no blockers; golden-set legal review passed or limitations written | Failing E2E becomes a documented manual smoke; failing gate is never waived |
| **G5** | 3:40 | Code freeze: only fixes for blockers found by the clean-clone check | - |

Cut order (stop at the first that restores the schedule): (1) spec 07 feedback, (2) Playwright automation becomes a manual checklist (axe component tests stay), (3) throttling beyond sign-in, (4) golden set reduced to 5 lawsuits, (5) U-9 e-SAJ styling polish. **Never cut:** TDD, the 80% gate, FR 1-5, secret hygiene, the README, WCAG basics for forms/keyboard/contrast.

## 9. Kickoff prompts (paste one per agent session)

Common header for every lane:

> You are the **<LANE>** lane for this repository. Read, in order: `AGENTS.md`, `docs/AI-GUARDRAILS.md`, `docs/plan/EXECUTION-PLAN-4H.md` (sections 4-8), `docs/contracts/README.md`, your role file `<role file>`, and the spec folders of your tasks. Work in your own worktree (`git worktree add ../wt-<lane> -b lane/<lane> main`, `COMPOSE_PROJECT_NAME=lawsuits-<lane>`). Do only your tasks, in the order of the schedule table, test first, inside your owned files. Log events to `docs/plan/log/<lane>.md`. Do not edit files you do not own; ask the owner lane through your log. Stop at the gate times and report.

Lane-specific tails:

| Lane | Tail |
|------|------|
| P | "Tasks F-1..F-5 first (this is gate G0 at T+0:30), compose project per lane, ports via env. Then CI, merges, README. You are the Integrator: merge lane PRs when green, post gates." |
| B1 | "Wave 0: draft task F-10 from `docs/contracts/` (stubs for every contract field, all migrations, Errors::Messages). Start executing at G0. F-10 must merge by G1." |
| B2 | "Wave 0: draft CnjNumber and BrlParser with specs; vectors are in `docs/contracts/README.md`. B2 finishes I-1 and I-2 first because B1's L-2 needs them." |
| B3 | "Wave 0: draft SessionToken. Your tests must not depend on other lanes: use `execute_graphql` from Q-1. You own the guard; keep a documented allow-list." |
| AI | "Wave 0: draft Classifier/Cleaner against the title table from Q-2. Build on plain value objects. Gemini facts are in ADR-0002's decision log; the key is in `.env` as GEMINI_API_KEY (copy it into your worktree; never print it)." |
| F1 | "Start immediately with host Node 22: scaffold, Apollo, proxy, codegen from `docs/contracts/schema.graphql`, MSW handlers from the contract and the shared test data." |
| F2 | "Start with design tokens that satisfy contrast ratios, AppShell with landmarks and skip link, then SummaryCard. Follow `docs/skills/accessibility-wcag.md` for every component and fill the PR checklist." |
| SEC | "Wave 0: review the plan and draft failing specs for headers, log filtering and GraphQL limits. Then execute SEC-1..SEC-4 as their prerequisites land. Review PRs flagged needs-sec-review within 10 minutes." |
| QA | "Q-1 and Q-2 are on the critical path of G1: deliver factories, `execute_graphql`, the small CSV fixture and the classifier titles YAML first. Then Legal reviews and E2E drafting." |

## 10. Definition of "done" for the 4 hours

- [ ] G5 passed; `main` is green; both coverage gates pass.
- [ ] Clean clone: `cp .env.example .env`, add `GEMINI_API_KEY`, `docker compose up --build` shows the app with data imported; README commands verified.
- [ ] Traceability table filled; security audit and accessibility audit recorded.
- [ ] Task checkboxes in specs reflect reality; cut items (if any) are listed in the README "Known limits".
- [ ] Repository ready for video and email (human steps).
