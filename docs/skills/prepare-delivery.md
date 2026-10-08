---
name: prepare-delivery
description: Final checklist to submit the challenge to Resolvvi - requirements trace, README check on a clean clone, coverage numbers, secrets scan, private repo sharing, demo video script (max 4 min) and the delivery email. Use in the last hours before the deadline.
---

# Skill: Prepare delivery

## Purpose
Meet every explicit rule of the challenge and make the reviewers' first run painless. New skill specific to this project.

## When to use
After spec 01-07 work is complete (or the cut line is reached), well before the deadline.

## Deadline
Set when the owner gives the timestamp of the challenge email: **deadline = email time + 48h**. Write it at the top of the [implementation plan](../plan/IMPLEMENTATION-PLAN.md). Plan to finish at least 2 hours early. **No commits after the deadline.**

## Checklist

### A. Requirements trace
Open the challenge file and tick each item with evidence (test name, screen or command).

| Item | Evidence |
|------|----------|
| FR1 CSV imported into the DB | `import:lawsuits` report: 100 lawsuits, 5,568 movements |
| FR2 Home with one field + Consultar | Component test + screenshot |
| FR3 Lawsuit page similar to the court page | Screenshot next to `data/html_link_portal` |
| FR4 LLM summary section | Request spec + screenshot |
| FR5 <= 3 paragraphs, plain language | Validator spec + golden-set review |
| NFR1 any language | README stack section |
| NFR2 >= 80% coverage | Coverage output pasted in README |
| NFR3 relational DB | PostgreSQL |
| NFR4 README with run steps + technologies | Verified on a clean clone |
| NFR5 AGENTS.md | Present and accurate |
| Diff 1-5 | Rails, React, GraphQL, auth, rating: each demonstrable |
| Commit messages in English | `git log --oneline` scan |

### B. Clean-clone test
```bash
git clone <repo> /tmp/delivery-check && cd /tmp/delivery-check
cp .env.example .env
docker compose up --build
# open the app, sign up, search 1001399-31.2023.8.26.0070, see data, movements and summary, rate it
docker compose run --rm api bundle exec rspec
docker compose run --rm web npm test -- --run
```
Every command must work exactly as written in the README. Fix the README, not your memory.

### C. Hygiene
- [ ] Secrets scan: `git log -p | grep -iE "api[_-]?key|secret|token|password"` reviewed; `.env` not tracked.
- [ ] No large or irrelevant files; `data/` intact.
- [ ] `data/lawsuits_movements.csv` is present in a fresh clone (check `.gitignore`; see plan Q9).
- [ ] README: status, stack and reasons, run, test, ENV table, LLM config (fake vs real), project layout, limits and assumptions (ordering tie-break, no password reset, only imported lawsuits), coverage numbers.
- [ ] If a real LLM key is needed for the best demo, README explains how to set it and that `fake` works without it.

### D. Repository and sharing
- [ ] Repository is **private** (GitHub).
- [ ] Shared with `ariel@resolvvi.com` and `tayllan@resolvvi.com` (read access is enough).
- [ ] Default branch has everything; CI green.

### E. Demo video (<= 4 minutes, Loom)
| Time | Content |
|------|---------|
| 0:00-0:30 | Problem and what the app does; stack in one sentence |
| 0:30-1:30 | Live demo: sign in, search a lawsuit, data, movements, summary, rating |
| 1:30-2:30 | Architecture: CSV import, GraphQL, summary pipeline (classify, clean, budget, cache), provider abstraction |
| 2:30-3:20 | Quality: TDD, coverage number, AGENTS.md and the agent roles/skills used |
| 3:20-4:00 | Decisions and limits: ordering tie-break, privacy (no lawyer names to LLM), what I would do next |
Record once with a rehearsed script; keep the link viewable without login.

### F. Email
To `ariel@resolvvi.com`, `tayllan@resolvvi.com`. Subject: `Technical challenge - <your name>`. Body: repository link, video link, 3 lines on stack and how to run, note on assumptions. Send before the deadline.

### G. Freeze
After sending: **stop committing and pushing**. Do not merge late PRs.

## Output
All boxes ticked; email sent; repository frozen.

## Common mistakes
- README commands never run on a clean clone.
- Using the challenge's example CNJ in the demo (it is not in the CSV; it returns "not found" by design).
- Video over 4 minutes.
- A "last small fix" commit after the deadline.
