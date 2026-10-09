# Security and dependency audit (D-5)

Run on 2026-10-09 against the working tree, inside the Compose containers.

| Check | Command | Result |
|-------|---------|--------|
| Static analysis (Rails) | `docker compose run --rm api bundle exec brakeman -q --no-pager` | 0 warnings, 0 errors (2 controllers, 7 models) |
| Ruby dependencies | `docker compose run --rm api bundle exec bundler-audit check` | No vulnerabilities found |
| JS dependencies | `npm audit --omit=dev` in `frontend/` | 0 vulnerabilities |
| Key patterns in the whole git history (`git log -p --all`: Google API keys, PEM private keys, `sk-`, `ghp_`, `AKIA`) | grep | 0 matches |
| `GEMINI_API_KEY` assignments in history | grep | Only the Compose pass-through `GEMINI_API_KEY: ${GEMINI_API_KEY:-}`; no value |
| `.env` ever tracked | `git log --all --name-only` | Never |
| Tracked env files | `git ls-files` filtered for `.env` | Only `.env.example` |
| Real LLM calls in tests and CI | `requests/webmock_guard_spec.rb` blocks network; CI sets `LLM_PROVIDER=fake`; the test environment always selects the fake provider | None |
| CI secret scan | `.github/workflows/ci.yml` greps tracked files for Google key patterns | Part of the backend job |

## Feedback feature review (spec 07)

| Concern | Control |
|---------|---------|
| Anonymous voting | Schema guard returns `UNAUTHENTICATED` before the resolver runs (`graphql/guard_spec.rb` iterates every root field, `rateSummary` included) |
| Reading other users' votes | `Summary.myFeedback` is batched per current user; no field exposes other users or aggregates (`graphql/rate_summary_spec.rb`) |
| Vote tampering across users | The user comes from the session context, never from an argument |
| Concurrent duplicate rows | Unique index plus `upsert` |
| Report leaks | `feedback:report` prints only counts per prompt version and model |
| Id enumeration | An unknown or malformed summary id returns the same `NOT_FOUND` |

## Findings and accepted risks

- No high or critical findings.
- Request counters for throttling live in process memory (documented in `docs/domains/authentication.md`); acceptable for the single-container demo.
- The git history scan covered the local repository only. Run it again on a fresh clone after the final push.
