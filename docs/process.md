# Process

> AI-assisted development flows. They chain skills, specs and docs. Adapted from the Doity admin process, simplified for a greenfield, single-repo project.

## Skills available

| Skill | File | When |
|-------|------|------|
| Start feature | [start-feature](skills/start-feature.md) | Before any spec task |
| Create implementation plan | [create-implementation-plan](skills/create-implementation-plan.md) | New or changed scope not covered by a spec |
| Write tests (TDD) | [write-tests-tdd](skills/write-tests-tdd.md) | Every code change |
| Investigate flow | [investigate-flow](skills/investigate-flow.md) | Understand code without changing it |
| Start bugfix | [start-bugfix](skills/start-bugfix.md) | A defect is reported |
| Write ADR | [write-adr](skills/write-adr.md) | Architecture or cross-cutting decision |
| Tune LLM summary | [tune-llm-summary](skills/tune-llm-summary.md) | Prompt, model or summary quality changes |
| Finish delivery docs | [finish-delivery-docs](skills/finish-delivery-docs.md) | After each completed task/spec |
| Create pull request | [create-pull-request](skills/create-pull-request.md) | Publish work for review |
| Prepare delivery | [prepare-delivery](skills/prepare-delivery.md) | Final submission |

## Roles

Architect, Backend, Frontend, AI, Legal Expert, QA, DevOps/Release: see [agents](agents/README.md).

## Flow 1: Spec task (default)

```
1. Open the spec folder (.kiro/specs/NN-name/): requirements.md, design.md, tasks.md
2. Skill: start-feature        -> confirm the next unchecked task, its requirements and its definition of done
3. Read AI-GUARDRAILS + the relevant docs/domains/*.md
4. Skill: write-tests-tdd      -> Red: write the failing test(s) for the task
5. Implement the minimum       -> Green
6. Refactor with tests green   -> run lint + full suite + coverage gate
7. Tick the task in tasks.md
8. Skill: finish-delivery-docs -> update domain docs / ADR / README if behavior or contracts changed
9. Commit (Conventional Commit, English); open PR when a spec or a coherent slice is done
```

## Flow 2: New scope not covered by a spec

```
1. Skill: start-feature (clarifying questions)
2. Skill: investigate-flow (if touching existing code)
3. Skill: create-implementation-plan -> add a spec or extend an existing tasks.md; wait for owner approval
4. Continue with Flow 1 from step 3
```

## Flow 3: Bugfix

```
1. Skill: start-bugfix -> reproduce, write the failing regression test (Red)
2. Fix with the smallest change (Green)
3. Run the suite + coverage gate
4. finish-delivery-docs only if a documented behavior changed
```

## Flow 4: Prompt / summary change

```
1. Skill: tune-llm-summary
2. Legal Expert reviews sample outputs against the glossary and the plain-language checklist
3. Bump PROMPT_VERSION, update prompt tests, update docs/domains/ai-summary.md
```

## Flow 5: Final delivery

```
1. Skill: prepare-delivery -> checklist, README check, coverage report, demo video script (<= 4 min)
2. Share the private repo with ariel@resolvvi.com and tayllan@resolvvi.com; email link + video
3. Stop committing
```

## Validation checkpoints

| Checkpoint | Who validates |
|------------|---------------|
| Spec requirements and design | Project owner |
| ADRs | Architect agent + owner |
| Summary prompt and sample outputs | Legal Expert agent + owner |
| Test strategy and coverage report | QA agent |
| Final README and delivery checklist | DevOps/Release agent + owner |

## Documents produced per flow

| Flow | Spec/tasks | ADR | Domain doc | Feature doc | README |
|------|:---------:|:---:|:----------:|:-----------:|:------:|
| Spec task | Tick | If a decision was made | If behavior changed | Optional | If run steps changed |
| New scope | Create | If needed | Update | Optional | If needed |
| Bugfix | - | - | If behavior changed | - | - |
| Prompt change | - | Optional | Update `ai-summary.md` | - | - |
| Delivery | - | - | - | - | Final check |
