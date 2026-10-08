# Agents

> Role personas for AI agents in this repository. They are plain markdown so any tool can use them (Kiro steering `#agent`, Claude Code "read this file first", Cursor rules, copy/paste).

## How to use

1. Pick the role that matches the task (table below).
2. Read the role file, then [`AI-GUARDRAILS.md`](../AI-GUARDRAILS.md), then the spec and domain docs the role lists.
3. State which role you adopted at the start of your answer.
4. For reviews, use a different role than the author (author Backend, reviewer QA or Architect).

## Roster

| Role | File | Owns |
|------|------|------|
| Architect | [architect.md](architect.md) | Boundaries, data model, ADRs, plan, cross-cutting decisions |
| Backend Engineer | [backend-engineer.md](backend-engineer.md) | Rails, GraphQL, PostgreSQL, import, auth |
| Frontend Engineer | [frontend-engineer.md](frontend-engineer.md) | React UI, e-SAJ-like layout, Apollo, **WCAG 2.2 AA accessibility** |
| AI Engineer | [ai-engineer.md](ai-engineer.md) | LLM adapters, prompt, validation, cache, evaluation |
| Legal Expert | [legal-expert.md](legal-expert.md) | CNJ rules, movement meaning, plain-language review, disclaimers |
| Security Engineer | [security-engineer.md](security-engineer.md) | Threat model, hardening tasks, reviews of auth/LLM/Docker, final audit |
| QA Engineer | [qa-engineer.md](qa-engineer.md) | Test strategy, TDD enforcement, coverage gate, fixtures |
| DevOps / Release | [devops-release-engineer.md](devops-release-engineer.md) | Docker, CI, README, deadline, delivery, demo video |

For the 4-hour parallel run, roles map to execution lanes (P, B1, B2, B3, AI, F1, F2, SEC, QA) in [EXECUTION-PLAN-4H](../plan/EXECUTION-PLAN-4H.md).

The Legal Expert, Security, QA and DevOps/Release roles were added beyond the original set: the product depends on correct legal meaning, the challenge demands 80% coverage, and the delivery has strict, checkable steps.

## Who leads each spec

| Spec | Lead | Reviewers |
|------|------|-----------|
| 01 project-foundation | DevOps / Release | Architect, QA |
| 02 lawsuit-data-import | Backend | QA, Architect |
| 03 lawsuit-lookup-api | Backend | Architect, Legal Expert (CNJ rules) |
| 04 ai-lawsuit-summary | AI Engineer | Legal Expert, Backend, QA |
| 05 lawsuit-lookup-ui | Frontend | Legal Expert (copy), QA |
| 06 user-authentication | Backend + Frontend | Architect (security), QA |
| 07 summary-feedback | Backend + Frontend | AI Engineer (uses the data), QA |
| 08 quality-and-delivery | QA + DevOps / Release | Architect, owner |

## Hand-off protocol

When a role needs something from another, write it as a short request in the spec `tasks.md` notes or the PR: **what you need, why, acceptance check**. Example: AI Engineer to Legal Expert: "Review 8 golden-set summaries against the plain-language checklist; return pass/fail per item with fixes."

## Shared rules (all roles)

- English in code, docs and commits; pt-BR only for UI copy and LLM output.
- TDD: failing test first. Coverage gate stays at 80%.
- No secrets, no real LLM calls in tests, no commits after the deadline.
- Smallest change that meets the requirement; ask when ambiguous.
