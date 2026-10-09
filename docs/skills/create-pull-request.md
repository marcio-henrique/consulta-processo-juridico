---
name: create-pull-request
description: Prepare and open a GitHub pull request - verify branch, review the diff, check tests/docs, write the description from the template, get approval, push and open the PR with gh. Use when a coherent slice of work is ready for review.
---

# Skill: Create pull request

## Purpose
Publish work with a clear, complete description. Adapted from the Doity "criar-pull-request" skill (Bitbucket + MCP) to GitHub and the `gh` CLI.

## When to use
A spec or a coherent slice of a spec is done, tests are green, docs are updated.

## Steps
1. **Branches.** Source = current branch (`git rev-parse --abbrev-ref HEAD`). Destination = `main` unless told otherwise. Stop if they are equal. Naming: `feat/<spec>-<slug>`, `fix/<slug>`, `docs/<slug>`.
2. **Deadline check.** If the challenge deadline has passed or is unknown, **stop and ask the owner**. No commits or pushes after the deadline.
3. **Review the diff.**
   ```bash
   git fetch origin
   git log origin/main..HEAD --oneline
   git diff origin/main...HEAD --stat
   ```
   Check: no secrets (`.env`, keys), no stray files, commit messages in English (Conventional Commits), no real LLM calls in tests.
4. **Verify.** Run the backend and frontend suites, linters and the coverage gate; paste the numbers.
5. **Docs.** Confirm [`finish-delivery-docs`](finish-delivery-docs.md) was done.
6. **Write title and description** from [`pull-request-description.md`](../templates/pull-request-description.md). Title under 70 characters, e.g. `feat: import lawsuits from CSV idempotently`.
7. **Show it to the owner and wait for approval.**
8. **Push and open.**
   ```bash
   git push -u origin <branch>
   gh pr create --base main --head <branch> --title "<title>" --body-file <file>
   ```
   Return the PR URL. If `gh` is not available, give the compare URL and the text to paste.

## Rules
- Never push to `main` directly or force-push unless the owner explicitly asks.
- One concern per PR; link the spec and requirement IDs.
- Do not merge your own PR without owner approval.

## Output
PR URL and a summary of what was verified.

## Common mistakes
- Opening the PR before running the full suite.
- Huge PRs mixing import, UI and auth.
- Forgetting to mention new ENV variables.
