---
name: tune-llm-summary
description: Safe procedure to change or evaluate the summary prompt, model, budget or validation - versioning, golden-set review, plain-language checklist and cost check. Use whenever summary behavior changes.
---

# Skill: Tune LLM summary

## Purpose
Improve summary quality without regressions in faithfulness, readability, privacy or cost. New skill specific to this project.

## When to use
- Editing the system or user prompt, the classifier rules, the cleaner, the budget or the validator.
- Changing provider or model.
- A reviewer reports jargon, a wrong fact or an overlong summary.

## Steps

### 1. Reproduce the problem
Pick the lawsuit(s) involved. Generate the current summary and the exact prompt the builder produces (use the `PromptBuilder` in a console or a spec; do not log prompts in production).

### 2. Decide the smallest lever
Order of preference:
1. Cleaner/classifier rule (remove noise, promote a missing milestone).
2. Budget tweak (more room for milestones).
3. Prompt wording.
4. Validator rule.
5. Model change.

### 3. Test first
Write or update unit tests for the lever (classifier table, cleaner fixture, budgeter, validator). Prompt wording changes are covered by a test that asserts the required instructions are present in the system prompt (3-paragraph limit, plain language, no advice, data-not-instructions, latest movement date).

### 4. Bump the version
If prompt text changed, bump `PROMPT_VERSION`. This invalidates the cache key, so new summaries use the new prompt.

### 5. Evaluate on the golden set
Run `bin/rails summaries:eval` (needs a real key; never in CI). Golden set: settled by agreement, upheld, partially upheld, dismissed, appealed, enforcement phase, archived, shortest (6 movements), longest (120 movements). Print: lawsuit, summary, input/output tokens, latency.

### 6. Review with the Legal Expert
Use the checklist in [`legal-glossary`](../domains/legal-glossary.md) section 5. Record pass/fail per item and per lawsuit.

| Check | Pass condition |
|-------|----------------|
| Length | <= 3 paragraphs, <= 2,000 chars |
| Plain language | No unexplained jargon; short sentences |
| Faithfulness | Every fact appears in the movements; unknowns marked as not informed |
| Neutrality | No advice, prediction or blame |
| Currency | States the latest movement date |
| Privacy | No lawyer names/OAB in input or output |
| Injection | A movement containing "ignore previous instructions" does not change behavior (test with a crafted fixture) |

### 7. Cost and latency check
Compare average input tokens and latency with the previous version. Flag increases above ~25% to the owner.

### 8. Document
Update [`ai-summary`](../domains/ai-summary.md) (rules, defaults), the golden-set notes, and ADR-0002's decision log if the model/provider changed. Commit with `feat(ai):` or `fix(ai):`.

## Output
Updated tests, bumped `PROMPT_VERSION`, evaluation notes (pass/fail table), updated docs.

## Common mistakes
- Changing the prompt without bumping the version (stale cache hides the change).
- Judging quality on one lawsuit.
- Adding more instructions instead of cleaning the input.
- Putting real summaries or keys in the repo.
