# Skills

> Tool-agnostic playbooks for recurring workflows. Adapted from the Doity admin skills (start-feature, create-plan, TDD, investigate, finish docs, PR), simplified for this greenfield project and extended with ADR, LLM tuning and delivery skills.

Each file starts with `name` and `description` frontmatter, so it can also be loaded as a Claude Code or Cursor skill if copied to `.claude/skills/<name>/SKILL.md` or `.cursor/skills/<name>/SKILL.md`.

| Skill | File | Use when | Primary role |
|-------|------|----------|--------------|
| start-feature | [start-feature.md](start-feature.md) | Before any spec task or new scope | Any |
| create-implementation-plan | [create-implementation-plan.md](create-implementation-plan.md) | Scope not covered by a spec, or a spec needs re-planning | Architect |
| write-tests-tdd | [write-tests-tdd.md](write-tests-tdd.md) | Every code change | QA / any |
| investigate-flow | [investigate-flow.md](investigate-flow.md) | Understand code without changing it | Any |
| start-bugfix | [start-bugfix.md](start-bugfix.md) | A defect is reported | Any |
| write-adr | [write-adr.md](write-adr.md) | A decision with trade-offs is made | Architect |
| tune-llm-summary | [tune-llm-summary.md](tune-llm-summary.md) | Prompt, model, budget or validation changes | AI + Legal |
| accessibility-wcag | [accessibility-wcag.md](accessibility-wcag.md) | Every UI task and the final audit | Frontend |
| security-review | [security-review.md](security-review.md) | Risky changes and the final audit | Security |
| finish-delivery-docs | [finish-delivery-docs.md](finish-delivery-docs.md) | After each completed task or spec | Any |
| create-pull-request | [create-pull-request.md](create-pull-request.md) | Publish a coherent slice for review | DevOps / any |
| prepare-delivery | [prepare-delivery.md](prepare-delivery.md) | Final submission to Resolvvi | DevOps / Release |

## Conventions for writing a new skill

1. File name = skill name, kebab-case, English.
2. Frontmatter with `name` and `description` (what it does and when to use it).
3. Sections: Purpose, When to use, Steps, Output, Common mistakes.
4. Under 150 lines; link to docs instead of copying them.
5. Register it here and in the skills table of `AGENTS.md`.
