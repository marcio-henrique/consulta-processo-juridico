---
name: start-feature
description: Entry workflow for any spec task or new feature. Confirms the goal, loads the right docs, checks guardrails and produces a short work plan before code is written. Use at the start of every task.
---

# Skill: Start feature

## Purpose
Understand the task fully before writing code. Adapted from the Doity "iniciar-feature" skill, with the long questionnaire reduced because most answers are already in the specs.

## When to use
Always, before implementing a task from `.kiro/specs/*/tasks.md` or any new request.

## Steps

### 1. Locate the work
- Identify the spec folder and the next unchecked task (`tasks.md`). Note its requirement IDs.
- Read `requirements.md` (acceptance criteria) and `design.md` (interfaces) of that spec.

### 2. Load context
- [`AI-GUARDRAILS.md`](../AI-GUARDRAILS.md) (always).
- The domain docs the task touches (`docs/domains/*.md`) and [`architecture.md`](../architecture.md).
- The role file you will adopt ([`agents/`](../agents/README.md)).

### 3. Ask only what is missing
If the answer is not in the docs, ask the owner. Typical gaps:
1. What exactly is "done" for this task? (a test, a screen, a command output)
2. Does it change a contract (GraphQL schema, ENV, table)? If yes, who approves?
3. Is there existing code or a similar feature to reuse?
4. Does it touch the LLM, PII, authentication or the import? (sensitive areas)
5. Any deadline or ordering constraint?

If you cannot ask, pick the simplest option and write the assumption in the task notes.

### 4. Investigate existing code
If code exists in the area, follow [`investigate-flow`](investigate-flow.md). Do not refactor during investigation.

### 5. State the work plan (5-10 lines)
```markdown
Task: <id and title>
Role: <role>
Done when: <verifiable outcome>
Tests to write first (Red): <list>
Files to create/modify: <list>
Risks / assumptions: <list>
Docs to update after: <list>
```
For a single spec task, proceed after stating the plan. For new scope or a contract change, wait for owner approval ([`create-implementation-plan`](create-implementation-plan.md)).

### 6. Hand over to TDD
Continue with [`write-tests-tdd`](write-tests-tdd.md).

## Output
A work plan and a list of confirmed assumptions. No production code yet.

## Common mistakes
- Starting to code from the task title without reading the acceptance criteria.
- Expanding scope because "it would be nice".
- Skipping guardrails when the change "is small".
