---
name: write-adr
description: Record an architecture decision (context, decision, alternatives, consequences) as a numbered ADR in docs/adr. Use when adding a dependency or service, changing a contract, or choosing between options with trade-offs.
---

# Skill: Write ADR

## Purpose
Make decisions visible and reversible. New skill (not present in the Doity admin repo) because this project has several choices reviewers will ask about: stack, LLM provider, sync vs async, auth.

## When to use
- New runtime dependency, service (Redis, queue), or top-level directory.
- Change to the data model rules, cache key, auth mechanism or LLM provider.
- Two reasonable options exist and the choice is not obvious.

Not needed for naming, formatting or other local choices.

## Steps
1. Next number: list `docs/adr/` and take the next four-digit number.
2. File: `docs/adr/NNNN-short-kebab-title.md`.
3. Fill the template below. Keep it under one page.
4. Link it from [`architecture.md`](../architecture.md) (ADR index) and from the spec design that triggered it.
5. If it supersedes an older ADR, set the old one to `Superseded by NNNN`.
6. Ask the Architect role (or the owner) to review. Status `Proposed` until approved, then `Accepted`.

## Template
```markdown
# ADR-NNNN: <title>

- Status: Proposed | Accepted | Superseded by NNNN
- Date: YYYY-MM-DD
- Deciders: <roles/people>

## Context
<forces, constraints, data that matter>

## Decision
<what we will do, in numbered points>

## Alternatives considered
| Alternative | Why not |
|-------------|---------|

## Consequences
<positive, negative, follow-ups, how to revisit>
```

## Common mistakes
- Writing the ADR after the code is merged and forgetting the alternatives.
- Listing only one alternative that nobody would pick.
- Leaving the status as Proposed forever.
