# Tasks: AI lawsuit summary

Lead: AI Engineer. Reviewers: Legal Expert, Backend, QA, Security. Status: implemented (A-1..A-13); Legal Expert review of the golden set (A-11) and the classifier table (A-3) is still pending.

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

- [x] **A-1. Choose the real provider and model** (0.5 h)
  - Check current provider docs (pricing, model ids, structured error format, rate limits). Pick one balancing cost, speed and pt-BR quality; ask the owner which API key is available.
  - Append the decision, model id and date to the decision log in [ADR-0002](../../../docs/adr/0002-llm-provider-abstraction.md); add the variables to `.env.example`.
  - _Requirements: 1.2_

- [x] **A-2. `Llm::Client`, errors, `Fake` provider** (0.75 h)
  - Red: client builds provider from ENV; `Fake` is deterministic and can be forced to fail; retry-once behavior for timeout/429/5xx using a stub provider.
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.6_

- [x] **A-3. `Movements::Classifier`** (0.75 h)
  - Red: YAML table of real titles -> class; unknown -> context. Rules from the [legal glossary](../../../docs/domains/legal-glossary.md). Ask the Legal Expert to review the table.
  - _Requirements: 2.1_

- [x] **A-4. `Movements::Cleaner`** (0.75 h)
  - Red: fixtures with `Teor do ato`, `Advogados(s)`, publication boilerplate; whitespace normalization; promotion rule.
  - _Requirements: 2.2, 2.3, 2.4_

- [x] **A-5. `Summaries::PromptBuilder` and prompt v1** (1.0 h)
  - Red: ordering, metadata, budget behavior on the longest real lawsuit, noise collapsing, no OAB pattern, required instructions present in the system prompt, injection fixture.
  - Write prompt text files (pt-BR) and `PROMPT_VERSION = "v1"`.
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 3.7_

- [x] **A-6. `Summaries::OutputValidator`** (0.5 h)
  - Red: blank, markdown, paragraph count, length, jargon warning.
  - _Requirements: 4.1, 4.2, 4.3, 4.4_

- [x] **A-7. Real provider adapter** (1.0 h)
  - Red: WebMock tests for 200, 429, 5xx, timeout, malformed body, missing key. Use Faraday with timeout from ENV.
  - Optional: a second adapter only if time allows (not required).
  - _Requirements: 1.3, 1.4, 1.5, 1.6_

- [x] **A-8. `summaries` migration and `Summary` model** (0.25 h)
  - Unique cache-key index; validations.
  - _Requirements: 5.1_

- [x] **A-9. `Summaries::Digest` and `Summaries::Generate`** (1.0 h)
  - Red: cache hit/miss, digest change, prompt-version change, failure persists nothing, corrective retry, two concurrent calls -> one provider call, unique-violation fallback.
  - Log provider/model/latency/tokens/cache-hit only.
  - _Requirements: 5.2, 5.3, 5.4, 5.5, 4.3, 7.1, 7.2_

- [x] **A-10. GraphQL: `Summary`, `latestSummary`, `generateSummary`** (0.75 h)
  - Red: `latestSummary` never calls the provider; mutation success; `INVALID_CNJ`, `NOT_FOUND`, `SUMMARY_UNAVAILABLE`.
  - Regenerate `backend/schema.graphql`.
  - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5_

- [x] **A-11. `summaries:eval` and golden set** (0.75 h)
  - Choose golden-set numbers from the CSV with the Legal Expert (agreement, upheld, partial, dismissed, appealed, enforcement, archived, shortest, longest). Run with the real key; save the outputs **outside the repo** or only anonymized notes.
  - Legal Expert reviews against the checklist ([tune-llm-summary](../../../docs/skills/tune-llm-summary.md)); iterate on prompt (bump version) if needed.
  - _Requirements: 8.1, 8.2, 8.3_

- [x] **A-12. Docs** (0.25 h)
  - Update [ai-summary](../../../docs/domains/ai-summary.md) with final constants and rules; ADR-0002 log; `.env.example`; README LLM section; run [finish-delivery-docs](../../../docs/skills/finish-delivery-docs.md).

## Definition of done (spec)
- [x] With `LLM_PROVIDER=fake`, the whole flow works offline.
- [ ] With a real key, golden-set summaries pass the Legal Expert checklist. Full golden set (10 lawsuits) run with Gemini and checked against the glossary checklist and the source data: 9 of 10 passed; the failure (`1000061-57.2025.8.26.0068`, garbled amount "R$ 8,000,00") led to `Summaries::AmountCheck` and the lawsuit now passes; `1005003-07.2023.8.26.0100` was swapped for `1004772-13.2022.8.26.0068` because it is an agreement, not an upheld claim. Still pending: review by a real lawyer.
- [x] No prompt, content or key appears in logs (checked by specs that capture log output: `generate_spec.rb`, `gemini_spec.rb`).
- [x] Gate green.

## Task added for the 4-hour parallel plan

- [x] **A-13. Pipeline over all 100 real lawsuits** · Lane B2 · ⏱ 20 · After: A-5 and I-8 (real data loaded)
  - Red/Green: a `:real_data` spec that, for each of the 100 imported lawsuits, runs classifier, cleaner and `PromptBuilder` and asserts: user prompt length <= `MAX_PROMPT_CHARS`; the first movement and the last 15 are present; no `OAB \d+` or `Advogado` pattern; milestone count > 0; no exception. Report the worst-case lawsuit (length, milestone share) in the PR.
  - Files: `backend/spec/integration/prompt_over_real_data_spec.rb` (read-only use of AI-owned classes)
  - _Requirements: 2.1, 2.2, 2.3, 3.3, 3.7_

## Implementation notes

- A-1 `Llm::RetryPolicy` passes each attempt `min(per-attempt timeout, remaining budget)`, which is how the 45 s deadline is enforced; no fallback attempt is made when less than 1 s is left.
- A-2/A-7: `Llm::TruncatedError < Llm::ProviderError` signals Gemini `MAX_TOKENS`; it is not retried by the policy and `Summaries::Generate` retries once with the stricter instruction.
- A-3: the classifier table is in `Movements::Classifier::RULES` (anchored regexes over accent-folded titles) and is checked against `spec/fixtures/classifier_titles.yml`. Rules beyond the glossary (appeal outcomes, urgent-relief decisions, `Indeferida a Petição Inicial`) are marked for Legal Expert review.
- A-4: the cleaner also removes the `Nº Protocolo:` line and the "Sr(a). Advogado(a): ..." notice appended to some decisions.
- A-5: when two movements carry the same cleaned text (the decision and its "Remetido ao DJE" publication), the text is kept once, preferring the `Teor do ato` one.
- A-9: `Summaries::AmountCheck` compares every `R$` amount of the answer with the numbers in the prompt (requirement 4.5); wrong amounts trigger the corrective retry and, if they persist, `SUMMARY_UNAVAILABLE`.
- A-9: the stored `model` is the configured primary model (part of the cache key), even if the fallback model answered.
- A-11: `Summaries::Evaluation` holds the logic (covered by specs); `lib/tasks/summaries.rake` is a thin wrapper. `LAWSUITS=n1,n2` overrides the golden set; `ALLOW_FAKE=1` allows the offline provider.
- A-13 result: all 100 lawsuits fit the 24,000-character budget without dropping anything; worst case is `1003553-62.2022.8.26.0068` (96 movements, 13,431 characters, 26 milestones).
- Authentication and the per-user throttle on `generateSummary` are added by spec 06 (guard), not here.
