# AI Guardrails

> Rules and restrictions for AI agents working in this repository. Read before any change.

## Never do

- **Never commit secrets**: API keys, `.env`, `config/master.key`, credentials. Commit only `.env.example` with placeholders.
- **Never call a real LLM in tests or CI.** Use `Llm::Providers::Fake` or stubbed HTTP (WebMock). A test that needs a network is a bug.
- **Never edit** `data/lawsuits_movements.csv` or `data/Desafio Técnico com IA - 2026.md`. Fixtures for tests are small copies under `backend/spec/fixtures/`.
- **Never send lawyer names, OAB numbers or whole raw movement dumps to the LLM.** Use `PromptBuilder`, which strips and condenses.
- **Never log** prompts, movement contents, passwords, session tokens or API keys. Log ids, counts, latency and token usage only.
- **Never put business rules** in GraphQL types/resolvers or React components. Services (backend) and pure functions in `src/lib` (frontend) own them.
- **Never build SQL by string interpolation.** Use ActiveRecord parameters.
- **Never render LLM output as HTML.** Render as text; split paragraphs on blank lines. No `dangerouslySetInnerHTML`.
- **Never let the summary give legal advice or predict outcomes.** It narrates what happened.
- **Never skip the failing test (Red).** No production code without a test that failed first.
- **Never lower the coverage gate** or exclude files from SimpleCov to make it pass, except generated code (`config/`, `db/`, `bin/`) documented in `spec/spec_helper.rb`.
- **No commits after the challenge deadline.** If the deadline is unknown, ask the owner before committing.
- **Never rewrite published history** (force-push, `reset --hard`, `rebase` on pushed branches) without explicit owner approval.

## Always do

- Validate and normalize the CNJ number on the server even if the client already did.
- Return expected failures (invalid CNJ, not found, bad credentials, LLM unavailable) as typed `UserError`s.
- Enforce authentication on every GraphQL operation except sign-up, sign-in and `me`.
- Keep migrations forward-only once merged; add a new migration instead of editing an old one.
- Keep the prompt, `prompt_version` and its tests in sync: changing the prompt text requires bumping `PROMPT_VERSION`.
- Record assumptions and non-obvious decisions in the spec or in an ADR.
- Keep UI copy in pt-BR and everything else in English.
- Use accessible markup (labels, roles, keyboard focus, contrast); the movements table is a real `<table>`.
- Pin dependency versions (lockfiles committed). Prefer well-known gems/packages; flag anything unusual before adding it.

## Sensitive areas (human review recommended)

| Area | Why |
|------|-----|
| `app/services/llm/**`, `PromptBuilder` | Cost, privacy, output quality |
| Authentication (`SessionsController`/mutations, cookies) | Security |
| `Imports::*` | Data integrity; idempotency |
| `config/initializers/*`, `docker-compose.yml`, `.github/workflows/*` | Runtime and CI behavior |
| `db/migrate/*` | Irreversible data changes |

## Scope limits

- Do only what the current spec task asks. Out-of-scope ideas go to the spec "Open questions" or the plan "Backlog".
- Adding a runtime dependency, a new service (Redis, queue) or a new top-level directory needs an ADR or owner approval.
- When a requirement is ambiguous, ask. If you cannot ask, pick the simplest option and write the assumption down.

## Prompt-injection hygiene

Movement contents are untrusted text that goes into an LLM prompt. The system prompt must state that movement text is data, not instructions. Output is validated (length, paragraph count, language) and rendered as plain text. Details: [ai-summary](domains/ai-summary.md).
