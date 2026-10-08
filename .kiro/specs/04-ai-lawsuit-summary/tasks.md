# Tasks: AI lawsuit summary

Lead: AI Engineer. Reviewers: Legal Expert, Backend, QA, Security. Status: not started.

## 4-hour execution board (overrides the hour estimates below)

Schedule and ownership: [EXECUTION-PLAN-4H](../../../docs/plan/EXECUTION-PLAN-4H.md). **The provider is already chosen: Gemini** ([ADR-0002](../../../docs/adr/0002-llm-provider-abstraction.md) decision log, with the verified models, headers and retry policy). Therefore **A-1 is now `Llm::RetryPolicy`** (the old "choose the provider" task is done) and **A-7 is the Gemini adapter** (no second adapter). The key is `GEMINI_API_KEY` in `.env` (copy into the AI and QA worktrees only; never print it).

| Task | Lane | ⏱ min | After | Needs |
|------|------|------:|-------|-------|
| A-1 `Llm::RetryPolicy` (2 retries 1 s/2 s, fallback model, 45 s deadline, injectable sleeper) | AI | 10 | G0 | - |
| A-2 `Llm::Client`, errors, `Result`, `Fake` provider, provider selection (`auto`/`gemini`/`fake`) | AI | 15 | A-1 | - |
| A-3 `Movements::Classifier` | AI | 12 | G0, Q-2 | value objects only |
| A-4 `Movements::Cleaner` | AI | 12 | A-3 | value objects only |
| A-5 `Summaries::PromptBuilder` + prompt v1 | AI | 20 | A-4 | Legal review of the prompt (QA lane) |
| A-6 `Summaries::OutputValidator` | AI | 10 | G0 | - |
| A-7 `Llm::Providers::Gemini` (WebMock) | AI | 20 | A-2 | SEC review (`needs-sec-review`) |
| A-8 `Summary` model: validations, `current_for` | AI | 5 | F-10 | - |
| A-9 `Summaries::Digest` + `Summaries::Generate` | AI | 25 | A-5, A-6, A-7, A-8, I-3 | - |
| A-10 GraphQL: `Summary` type, `latestSummary`, `generateSummary` | AI | 12 | A-9, F-10 | - |
| A-11 `summaries:eval` + golden-set run with Gemini | AI | 15 | A-10, I-7 (data loaded) | `.env` key |
| A-12 Docs | AI | 5 | A-11 | - |
| A-13 Pipeline over all 100 real lawsuits (budget, first/last kept, no OAB pattern) | B2 | 20 | A-5, I-8 | - |

The task texts below keep their original wording; where they conflict with this board (A-1, A-7, estimates, the optional second adapter), the board wins.

- [ ] **A-1. Choose the real provider and model** (0.5 h)
  - Check current provider docs (pricing, model ids, structured error format, rate limits). Pick one balancing cost, speed and pt-BR quality; ask the owner which API key is available.
  - Append the decision, model id and date to the decision log in [ADR-0002](../../../docs/adr/0002-llm-provider-abstraction.md); add the variables to `.env.example`.
  - _Requirements: 1.2_

- [ ] **A-2. `Llm::Client`, errors, `Fake` provider** (0.75 h)
  - Red: client builds provider from ENV; `Fake` is deterministic and can be forced to fail; retry-once behavior for timeout/429/5xx using a stub provider.
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.6_

- [ ] **A-3. `Movements::Classifier`** (0.75 h)
  - Red: YAML table of real titles -> class; unknown -> context. Rules from the [legal glossary](../../../docs/domains/legal-glossary.md). Ask the Legal Expert to review the table.
  - _Requirements: 2.1_

- [ ] **A-4. `Movements::Cleaner`** (0.75 h)
  - Red: fixtures with `Teor do ato`, `Advogados(s)`, publication boilerplate; whitespace normalization; promotion rule.
  - _Requirements: 2.2, 2.3, 2.4_

- [ ] **A-5. `Summaries::PromptBuilder` and prompt v1** (1.0 h)
  - Red: ordering, metadata, budget behavior on the longest real lawsuit, noise collapsing, no OAB pattern, required instructions present in the system prompt, injection fixture.
  - Write prompt text files (pt-BR) and `PROMPT_VERSION = "v1"`.
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 3.7_

- [ ] **A-6. `Summaries::OutputValidator`** (0.5 h)
  - Red: blank, markdown, paragraph count, length, jargon warning.
  - _Requirements: 4.1, 4.2, 4.3, 4.4_

- [ ] **A-7. Real provider adapter** (1.0 h)
  - Red: WebMock tests for 200, 429, 5xx, timeout, malformed body, missing key. Use Faraday with timeout from ENV.
  - Optional: a second adapter only if time allows (not required).
  - _Requirements: 1.3, 1.4, 1.5, 1.6_

- [ ] **A-8. `summaries` migration and `Summary` model** (0.25 h)
  - Unique cache-key index; validations.
  - _Requirements: 5.1_

- [ ] **A-9. `Summaries::Digest` and `Summaries::Generate`** (1.0 h)
  - Red: cache hit/miss, digest change, prompt-version change, failure persists nothing, corrective retry, two concurrent calls -> one provider call, unique-violation fallback.
  - Log provider/model/latency/tokens/cache-hit only.
  - _Requirements: 5.2, 5.3, 5.4, 5.5, 4.3, 7.1, 7.2_

- [ ] **A-10. GraphQL: `Summary`, `latestSummary`, `generateSummary`** (0.75 h)
  - Red: `latestSummary` never calls the provider; mutation success; `INVALID_CNJ`, `NOT_FOUND`, `SUMMARY_UNAVAILABLE`.
  - Regenerate `backend/schema.graphql`.
  - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5_

- [ ] **A-11. `summaries:eval` and golden set** (0.75 h)
  - Choose golden-set numbers from the CSV with the Legal Expert (agreement, upheld, partial, dismissed, appealed, enforcement, archived, shortest, longest). Run with the real key; save the outputs **outside the repo** or only anonymized notes.
  - Legal Expert reviews against the checklist ([tune-llm-summary](../../../docs/skills/tune-llm-summary.md)); iterate on prompt (bump version) if needed.
  - _Requirements: 8.1, 8.2, 8.3_

- [ ] **A-12. Docs** (0.25 h)
  - Update [ai-summary](../../../docs/domains/ai-summary.md) with final constants and rules; ADR-0002 log; `.env.example`; README LLM section; run [finish-delivery-docs](../../../docs/skills/finish-delivery-docs.md).

## Definition of done (spec)
- [ ] With `LLM_PROVIDER=fake`, the whole flow works offline.
- [ ] With a real key, golden-set summaries pass the Legal Expert checklist.
- [ ] No prompt, content or key appears in logs (checked by a spec that captures log output).
- [ ] Gate green.

## Task added for the 4-hour parallel plan

- [ ] **A-13. Pipeline over all 100 real lawsuits** · Lane B2 · ⏱ 20 · After: A-5 and I-8 (real data loaded)
  - Red/Green: a `:real_data` spec that, for each of the 100 imported lawsuits, runs classifier, cleaner and `PromptBuilder` and asserts: user prompt length <= `MAX_PROMPT_CHARS`; the first movement and the last 15 are present; no `OAB \d+` or `Advogado` pattern; milestone count > 0; no exception. Report the worst-case lawsuit (length, milestone share) in the PR.
  - Files: `backend/spec/integration/prompt_over_real_data_spec.rb` (read-only use of AI-owned classes)
  - _Requirements: 2.1, 2.2, 2.3, 3.3, 3.7_
