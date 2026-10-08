---
name: create-implementation-plan
description: Produces a structured implementation plan (scope, GraphQL/DB/UI impact, risks, test strategy, file list, sequence) for work not already covered by a spec, and waits for approval. Use for new scope or major re-planning.
---

# Skill: Create implementation plan

## Purpose
Turn a goal into a reviewable plan before code. Adapted from the Doity "criar-plano-implementacao" skill, with the CakePHP sections replaced by Rails, GraphQL and React ones.

## When to use
- New scope that has no spec yet.
- A spec needs significant change (new table, new GraphQL type, new dependency).
- The owner asks for a plan.

For work fully described by an existing spec, the spec's `tasks.md` is the plan; use [`start-feature`](start-feature.md) instead.

## Steps
1. Consolidate the goal, constraints and answers from [`start-feature`](start-feature.md).
2. Map the impact with [`investigate-flow`](investigate-flow.md) (existing code) and the docs.
3. List risks and mitigations.
4. Define the test strategy (layers, scenarios, edge cases, regressions).
5. Write the plan in the format below, save it as a spec (`.kiro/specs/NN-name/`) or in the PR/issue, and **wait for explicit approval**.

## Format

```markdown
## Implementation plan: <name>

### Goal and requirement IDs
<what and why; challenge items FR/NFR/Diff and spec requirement IDs>

### Backend impact
| Area | File(s) | Change |
|------|---------|--------|
| Migration/model | | create/modify |
| GraphQL | | type/query/mutation |
| Service / lib | | create/modify |

### Frontend impact
| Area | File(s) | Change |
|------|---------|--------|
| Page/component | | |
| GraphQL operation | | |

### Integrations and config
| Item | Impact |
|------|--------|
| LLM provider | |
| ENV variables | |
| Docker / CI | |

### Risks
- **<risk>:** <mitigation>

### Test strategy (Red first)
| Scenario | Layer (unit / request / component / E2E) |
|----------|------------------------------------------|
| Happy path | |
| Edge case | |
| Regression to lock | |

### Sequence
1. Write failing tests
2. Implement (Green)
3. Refactor, lint, coverage gate
4. Docs ([`finish-delivery-docs`](finish-delivery-docs.md))

### Docs and ADRs affected
<list>

### Estimate
<hours per step; total; fits the deadline? what gets cut if not?>

**Awaiting approval.**
```

## Output
A plan document and an explicit approval (or requested changes). No production files changed.

## Common mistakes
- No estimate or no cut line, so the deadline slips silently.
- Forgetting ENV, Docker or CI impact.
- Plans with no failing-test step.
