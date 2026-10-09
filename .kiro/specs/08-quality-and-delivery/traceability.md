# Traceability

Which test (or manual evidence) proves each challenge item and each spec requirement group. Paths are relative to `backend/spec/` for Ruby files and `frontend/` for TypeScript files. "E2E" is `frontend/playwright/lookup.spec.ts` (needs the running stack; see the README).

## Challenge items

| Item | Spec requirement(s) | Evidence |
|------|---------------------|----------|
| FR 1 Import CSV into the DB | 02: 1-6 | `services/imports/lawsuits_csv_spec.rb`, `integration/real_csv_import_spec.rb` (100 lawsuits, 5,568 movements), `tasks/import_rake_spec.rb`, `db/seeds_spec.rb` |
| FR 2 Home with one field and Consultar | 05: 1, 8 | `src/components/CnjSearchForm.test.tsx`, `src/pages/HomePage.test.tsx`, `src/lib/cnj.test.ts`, E2E |
| FR 3 Lawsuit page like the court page | 03: 1-5; 05: 2, 3, 5, 6 | `graphql/lawsuit_query_spec.rb`, `graphql/lawsuit_query_count_spec.rb`, `services/lawsuits/*`, `src/components/LawsuitData.test.tsx`, `MovementsTable.test.tsx`, `src/pages/LawsuitPage.test.tsx`, E2E. Visual similarity to `data/html_link_portal`: manual (screenshot side by side), because a layout match cannot be asserted automatically |
| FR 4 LLM summary section | 04: 1-6; 05: 4 | `graphql/summary_spec.rb`, `services/summaries/generate_spec.rb`, `services/llm/*`, `src/components/SummaryCard.test.tsx`, E2E (fake provider). Real Gemini: manual via `summaries:eval` (needs a key, never in CI) |
| FR 5 At most 3 paragraphs, plain language | 04: 3, 4, 8 | `services/summaries/output_validator_spec.rb`, `prompt_builder_spec.rb`, `integration/prompt_over_real_data_spec.rb`. Plain-language quality: manual golden-set review (README "Assumptions and limits"), because readability is a human judgment |
| NFR 1 Any language | - | README stack section (Ruby on Rails + React) |
| NFR 2 Coverage >= 80% | 08: 1 | SimpleCov gate in `spec_helper.rb` (fails below 80% lines); Vitest thresholds in `vite.config.ts`. Numbers in the README |
| NFR 3 Relational DB | 01: 3; 02: 3 | PostgreSQL; `db/migrations_spec.rb` |
| NFR 4 README with run steps and technologies | 01: 6; 08: 5 | Manual: clean-clone run (`prepare-delivery.md` section B) |
| NFR 5 AGENTS.md | 01: 6; 08: 5 | Manual: file reviewed against the real tree and commands |
| Diff 1 Rails backend | 01: 3 | `rails_helper.rb` suite (Rails 8.1 API mode) |
| Diff 2 React frontend | 01: 4; 05 | Vitest suite, E2E |
| Diff 3 GraphQL API | 01: 7; 03: 4 | `graphql/backend_schema_contract_spec.rb`, `bin/contract_check` (schema equals `docs/contracts/schema.graphql`), `requests/graphql_spec.rb` |
| Diff 4 User authentication | 06: 1-7 | See spec 06 below |
| Diff 5 Rate the summary | 07: 1-5 | See spec 07 below |
| Commit messages in English | 08: 7.4 | Manual: `git log --format=%s` scan (no accented characters found in the subjects) |

## Spec 01: project foundation

| Requirement | Evidence |
|-------------|----------|
| 1 Repository hygiene | Manual: `.gitignore`, `git ls-files` shows only `.env.example` for env files |
| 2 One-command environment | Manual: `docker compose up --build` on a clean clone |
| 3 Backend skeleton and test tooling | `requests/health_spec.rb`, `requests/graphql_spec.rb`, `requests/webmock_guard_spec.rb` |
| 4 Frontend skeleton and test tooling | `src/App.test.tsx` |
| 5 CI | `.github/workflows/ci.yml` (runs on every push and pull request) |
| 6 README and AGENTS.md accuracy | Manual |
| 7 Contract stubs and shared test support | `lib/factories_spec.rb`, `lib/graphql_helpers_spec.rb`, `graphql/backend_schema_contract_spec.rb` |
| 8 Environment for parallel agents | Manual (`docs/plan/EXECUTION-PLAN-4H.md`) |

## Spec 02: data import

| Requirement | Evidence |
|-------------|----------|
| 1 CNJ number handling | `lib/cnj_number_spec.rb` |
| 2 Number and date parsing | `lib/brl_parser_spec.rb`, `lib/money_formatter_spec.rb` |
| 3 Schema | `db/migrations_spec.rb`, `models/lawsuit_spec.rb`, `models/movement_spec.rb` |
| 4 Import behavior | `services/imports/lawsuits_csv_spec.rb` |
| 5 Report and entry points | `services/imports/report_spec.rb`, `tasks/import_rake_spec.rb`, `db/seeds_spec.rb` |
| 6 Real data check | `integration/real_csv_import_spec.rb` |

## Spec 03: lawsuit lookup API

| Requirement | Evidence |
|-------------|----------|
| 1 Find a lawsuit | `services/lawsuits/find_spec.rb`, `graphql/lawsuit_query_spec.rb` |
| 2 Lawsuit fields | `graphql/lawsuit_query_spec.rb` |
| 3 Movements, ordering, pagination | `services/lawsuits/movements_page_spec.rb`, `graphql/lawsuit_query_spec.rb` |
| 4 Error conventions | `graphql/lawsuit_query_spec.rb`, `graphql/guard_spec.rb` |
| 5 Performance and safety | `graphql/lawsuit_query_count_spec.rb`, `graphql/graphql_limits_spec.rb`, `graphql/schema_limits_spec.rb` |

## Spec 04: AI summary

| Requirement | Evidence |
|-------------|----------|
| 1 Provider abstraction | `services/llm/client_spec.rb`, `services/llm/providers/*`, `services/llm/retry_policy_spec.rb` |
| 2 Classification and cleaning | `services/movements/classifier_spec.rb`, `cleaner_spec.rb`, `lib/classifier_titles_fixture_spec.rb` |
| 3 Prompt building | `services/summaries/prompt_builder_spec.rb`, `integration/prompt_over_real_data_spec.rb` |
| 4 Output validation | `services/summaries/output_validator_spec.rb`, `amount_check_spec.rb` |
| 5 Persistence and cache | `services/summaries/generate_spec.rb`, `digest_spec.rb`, `models/summary_spec.rb` |
| 6 GraphQL exposure | `graphql/summary_spec.rb` |
| 7 Observability and privacy | `services/summaries/generate_spec.rb`, `requests/log_filtering_spec.rb` |
| 8 Quality evaluation | `services/summaries/evaluation_spec.rb`, `tasks/summaries_rake_spec.rb`; real-model review is manual |

## Spec 05: lookup UI

| Requirement | Evidence |
|-------------|----------|
| 1 Home page | `src/pages/HomePage.test.tsx`, `src/components/CnjSearchForm.test.tsx` |
| 2 Lawsuit page data | `src/components/LawsuitData.test.tsx`, `LawsuitHeader.test.tsx`, `src/pages/LawsuitPage.test.tsx` |
| 3 Movements table | `src/components/MovementsTable.test.tsx`, E2E (paging 25 to 46) |
| 4 Summary section | `src/components/SummaryCard.test.tsx`, `src/pages/LawsuitPage.test.tsx` |
| 5 Page states | `src/pages/LawsuitPage.test.tsx`, E2E (not found) |
| 6 Look and responsiveness | E2E (320 px reflow); visual match to the court page: manual |
| 7 Accessibility | axe in the component tests, axe in E2E on login, sign-up, lawsuit and not-found pages; manual audit in `accessibility-audit.md` |
| 8 Client-side CNJ helper | `src/lib/cnj.test.ts`, `src/lib/format.test.ts` |

## Spec 06: authentication

| Requirement | Evidence |
|-------------|----------|
| 1 Sign up | `services/auth/sign_up_spec.rb`, `models/user_spec.rb`, `src/pages/SignUpPage.test.tsx` |
| 2 Sign in and sign out | `services/auth/sign_in_spec.rb`, `authenticate_and_sign_out_spec.rb`, `src/pages/LoginPage.test.tsx` |
| 3 Session security | `models/session_spec.rb`, `lib/auth/session_token_spec.rb`, `lib/auth/session_cookie_spec.rb`, `requests/authentication_spec.rb`, E2E (HttpOnly, SameSite=Lax, empty web storage) |
| 4 Authorization | `graphql/guard_spec.rb` (iterates every root field) |
| 5 Request protection and throttling | `requests/throttling_spec.rb` |
| 6 Frontend authentication | `src/auth/*.test.tsx`, `src/auth/safeNext.test.ts`, `src/auth/unauthenticatedLink.test.ts`, E2E |
| 7 Security hardening | `requests/security_headers_spec.rb`, `requests/log_filtering_spec.rb`, `graphql/graphql_limits_spec.rb` |

## Spec 07: summary feedback

| Requirement | Evidence |
|-------------|----------|
| 1 Store feedback | `models/summary_feedback_spec.rb`, `db/migrations_spec.rb` |
| 2 Rate a summary | `services/feedback/rate_spec.rb`, `graphql/rate_summary_spec.rb`, `graphql/guard_spec.rb` |
| 3 Read own vote | `graphql/rate_summary_spec.rb` (per-user isolation, batching, no extra fields) |
| 4 Feedback UI | `src/components/FeedbackButtons.test.tsx`, `src/components/SummaryCard.test.tsx`, E2E |
| 5 Reporting | `tasks/feedback_rake_spec.rb` |

## Spec 08: quality and delivery

| Requirement | Evidence |
|-------------|----------|
| 1 Coverage evidence | Both gates fail the run below the threshold; numbers and exclusions in the README |
| 2 Traceability | This file |
| 3 End-to-end smoke | `frontend/playwright/lookup.spec.ts` |
| 4 Security and dependency checks | Results in `security-audit.md` |
| 5 README and AGENTS.md | Manual: clean-clone run |
| 6 Final requirements check | `accessibility-audit.md`, `security-audit.md`, golden-set review notes in the README |
| 7 Delivery | Manual, owner steps: private repository, sharing, video, email, freeze. Not automatable and not done by the agent |
