---
name: finish-delivery-docs
description: Closing checklist after a task or spec is implemented - tick tasks, update domain docs, architecture, ADRs, README and the plan, and verify docs match code. Use after each completed task or spec.
---

# Skill: Finish delivery docs

## Purpose
Keep documentation true after every change. Adapted from the Doity "finalizar-documentacao-entrega" skill, without the external wiki, Discord notice and Terms-of-Use steps (not applicable here).

## When to use
- A spec task or a whole spec is done.
- After follow-up adjustments in the same delivery, if they change documented behavior.

## Steps
1. **Tick** the task(s) in `.kiro/specs/NN-name/tasks.md`. If the spec is complete, mark its status line.
2. **Compare code and docs** for what you changed:

| If you changed | Update |
|----------------|--------|
| Table, column, index | [`architecture.md`](../architecture.md) ER diagram and constraints |
| GraphQL type/operation/error code | `architecture.md` schema sketch + the domain doc |
| Import parsing/ordering | [`data-import.md`](../domains/data-import.md) |
| CNJ rules, pages, copy | [`lawsuit-lookup.md`](../domains/lawsuit-lookup.md) |
| Prompt, classifier, validator, providers | [`ai-summary.md`](../domains/ai-summary.md), [`legal-glossary.md`](../domains/legal-glossary.md) |
| Sessions, cookies, throttling, feedback | [`authentication.md`](../domains/authentication.md) |
| ENV var, command, port, Docker | README, `.env.example`, AGENTS.md "Common commands" |
| A decision with trade-offs | New or updated ADR ([`write-adr`](write-adr.md)) |
| Scope, estimate, order | [`IMPLEMENTATION-PLAN.md`](../plan/IMPLEMENTATION-PLAN.md) |

3. **Feature doc (optional)**: for a non-trivial feature create `docs/features/<name>.md` from [`_TEMPLATE.md`](../features/_TEMPLATE.md).
4. **Traceability**: if tests were added for requirement IDs, update the traceability table in spec 08 (when it exists).
5. **Verify**: run the commands you documented; click the links you added.
6. **Summarize** in the PR: docs touched, or "no doc impact" with the reason.

## Output
Docs consistent with code; ticked tasks; PR note.

## Common mistakes
- Updating the README but not AGENTS.md commands (or vice versa).
- Documenting intended behavior instead of implemented behavior.
- Leaving "TODO" markers instead of opening a task in the spec.
