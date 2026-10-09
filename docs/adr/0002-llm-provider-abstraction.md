# ADR-0002: LLM provider abstraction

- Status: Accepted
- Date: 2026-10-07
- Deciders: Project owner, Architect agent, AI Engineer agent

## Context

The challenge says "an LLM of your choice". The reviewers will run the project, probably without our API key. Tests and CI must never hit a paid API. Providers and model names change often.

## Decision

1. Define a small interface `Llm::Client#complete(system:, user:, max_output_tokens:)` returning `Llm::Result(text:, input_tokens:, output_tokens:, model:)`.
2. Implement thin adapters under `Llm::Providers::` using Faraday (no vendor SDK): **`Gemini`** (the real provider, decided by the owner) and `Fake`. Other providers can be added later behind the same interface; none is planned.
3. Select the provider by ENV: `LLM_PROVIDER` (`auto` | `gemini` | `fake`), `LLM_MODEL`, `LLM_FALLBACK_MODEL`, `LLM_TIMEOUT_SECONDS`, and the secret `GEMINI_API_KEY`. `auto` (default) uses Gemini when `GEMINI_API_KEY` is present and the offline `Fake` otherwise. The test environment always uses `Fake` unless a spec injects a stubbed provider.
4. `Fake` returns a deterministic, valid 2-3 paragraph pt-BR summary built from lawsuit metadata, so the whole app is demoable without a key.
5. The provider and model were chosen on 2026-10-08 and verified with the owner's key (see the decision log below).
6. Adapter contract tests run against WebMock-stubbed HTTP responses recorded by hand (no VCR cassettes with secrets).

## Alternatives considered

| Alternative | Why not |
|-------------|---------|
| Vendor SDK directly in services | Lock-in; harder to fake; more dependencies |
| LangChain-style framework (`langchainrb`) | Heavy for one call; hides prompts |
| Local model (Ollama) as the default | Reviewers would need a model download; slow and heavy |
| Hard-code one provider | Fragile if the key or model is unavailable at review time |

## Consequences

- One small interface to test and mock.
- The README documents how to set a real key and how the `fake` provider behaves.
- Output quality evaluation is manual (`summaries:eval`) and requires a real key; it is not part of CI.
- `provider` and `model` are stored with each summary, so results are traceable and cache keys change when the model changes.

## Decision log

### 2026-10-08: Gemini via REST

- Owner decision: use a Gemini model; the key lives in `.env` as `GEMINI_API_KEY` (git-ignored).
- Endpoint: `POST https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent`.
- Authentication: header **`x-goog-api-key`**, never the `?key=` query parameter, so the key cannot end up in URLs, proxies or access logs.
- Request: `systemInstruction.parts[].text`, `contents[{role: "user", parts: [{text}]}]`, `generationConfig {temperature: 0.2, maxOutputTokens: 1024}`.
- Response: `candidates[0].content.parts[].text`, `candidates[0].finishReason`, `usageMetadata.{promptTokenCount, candidatesTokenCount, thoughtsTokenCount}`.
- Smoke test results with the owner's key (values of the key never printed):

| Model | Result |
|-------|--------|
| `gemini-3.5-flash-lite` | HTTP 200, no thinking tokens, 1-11 s. **Default (`LLM_MODEL`)** |
| `gemini-3.1-flash-lite` | HTTP 200, 1-2 s. **Fallback (`LLM_FALLBACK_MODEL`)** |
| `gemini-3.8-flash` | HTTP 200 but spends hidden "thinking" tokens (381 thought tokens consumed a 400-token output budget, leaving 15 visible tokens). Not used by default |
| `gemini-2.5-flash` | HTTP 404 "no longer available to new users" |

- Observed transient `503 high demand` on every model and latency spikes up to 44 s. Therefore:
  - per-attempt timeout `LLM_TIMEOUT_SECONDS` (default 20);
  - up to 2 retries on timeout, 429, 500, 503 with 1 s then 2 s backoff;
  - then a single attempt with `LLM_FALLBACK_MODEL`;
  - total deadline about 45 s, after which the call fails with `Llm::TimeoutError`.
- `finishReason` other than `STOP` is handled explicitly: `MAX_TOKENS` is treated as a truncated answer (retry once with a stricter prompt, then fail), `SAFETY` or a `promptFeedback.blockReason` becomes `Llm::ProviderError`.
- Models that think need a larger `maxOutputTokens`; if `LLM_MODEL` is changed to such a model, raise the budget and re-run the golden set.
- The model name is stored on each summary (`summaries.model`), so a model change creates new cache entries.
- Model ids and availability change often; re-verify with the deprecations page before delivery.
