---
name: start-bugfix
description: Workflow for fixing a defect - reproduce, write a failing regression test, apply the smallest fix, verify. Use whenever behavior deviates from the specs or docs.
---

# Skill: Start bugfix

## Purpose
Fix defects with minimal change and a regression test. Adapted from the Doity "iniciar-correcao" and "criar-hotfix" skills, reduced for a single-repo project.

## When to use
A defect is reported (by the owner, a test, CI or a reviewer).

## Steps
1. **Describe**: expected vs actual, steps to reproduce, data used (lawsuit number, input), environment. Ask for missing facts.
2. **Locate the requirement**: which spec requirement or domain rule is violated? If none, ask whether the behavior is a bug or a missing requirement.
3. **Investigate**: [`investigate-flow`](investigate-flow.md) on the failing path. Form a hypothesis from evidence (logs by request id, failing assertion), not from guesses.
4. **Red**: write a test that reproduces the bug at the lowest sensible layer ([`write-tests-tdd`](write-tests-tdd.md)). It must fail now.
5. **Fix**: smallest change that makes it pass. No drive-by refactors.
6. **Verify**: full suite for the side touched, coverage gate, linters. Re-run the manual reproduction if there was one.
7. **Root cause note**: one or two lines in the commit body or PR (why it happened, why this fix).
8. **Docs**: update a domain doc only if documented behavior changed ([`finish-delivery-docs`](finish-delivery-docs.md)).

## Triage hints
| Symptom | Look at first |
|---------|---------------|
| Wrong order of movements | `source_row` tie-break, ordering scope ([ADR-0005](../adr/0005-movement-ordering-and-idempotent-import.md)) |
| Wrong value shown | `BrlParser`, decimal column, formatting in `format.ts` |
| Valid number rejected | `CnjNumber` normalization and check digit |
| Summary stale or repeated calls | `movements_digest`, `PROMPT_VERSION`, unique index, advisory lock |
| Summary has legalese or too long | Prompt, validator, classifier ([`tune-llm-summary`](tune-llm-summary.md)) |
| 401-like behavior | Cookie flags, session expiry, Origin check, proxy config |

## Output
Failing test, fix, passing suite, short root-cause note.

## Common mistakes
- Fixing without a regression test.
- Changing the test to match the bug.
- Treating a missing requirement as a bug without asking.
