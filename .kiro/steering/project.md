---
inclusion: always
---

# Project steering

This project's canonical agent instructions live in `AGENTS.md` (tool-agnostic). Kiro loads them here so they are always in context. Everything is written in English; only UI copy and LLM output for end users are pt-BR.

#[[file:AGENTS.md]]

#[[file:docs/AI-GUARDRAILS.md]]

## Kiro-specific notes

- Specs live in `.kiro/specs/NN-name/` (`requirements.md`, `design.md`, `tasks.md`). Work tasks in order and tick them.
- Role personas are available on demand: type `#agent-architect`, `#agent-backend`, `#agent-frontend`, `#agent-ai`, `#agent-legal`, `#agent-security`, `#agent-qa`, `#agent-devops` in chat.
- Workflow playbooks are available on demand: `#workflow-feature` (start a task with TDD), `#workflow-delivery` (final submission).
- Implementation plan and timeline: `docs/plan/IMPLEMENTATION-PLAN.md`.
- **4-hour parallel execution plan (lanes, gates, cut line):** `docs/plan/EXECUTION-PLAN-4H.md`. This is the authoritative schedule; `IMPLEMENTATION-PLAN.md` sections 5-6 are superseded by it.
- Shared contracts (GraphQL schema, pt-BR error messages, test vectors): `docs/contracts/README.md`.
