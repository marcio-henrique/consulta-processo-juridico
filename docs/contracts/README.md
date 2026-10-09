# Contracts and shared test data

> Everything lanes must agree on **before** coding in parallel. Read this once; do not re-negotiate it in chat. Owner: Architect (change control), with Backend, Frontend and QA as reviewers.

## 1. Change control

1. [`schema.graphql`](schema.graphql) is the GraphQL contract. Frontend lanes generate types and MSW mocks from it from minute 0. Backend lanes implement it exactly.
2. To change a contract: edit the file in a small PR labeled `contract-change`, mention every affected task ID in the description, and notify the affected lanes (note in the execution log, see the execution plan). Additive changes are cheap; renames and removals need Architect approval.
3. When the backend generates `backend/schema.graphql` (task F-11), the Architect diffs it against this file. Any difference is either fixed in the code or recorded here. After gate G2, `backend/schema.graphql` is the generated reference and this file only holds the intent.

## 2. User-facing error messages (pt-BR)

| Code | Message | Field |
|------|---------|-------|
| `INVALID_CNJ` | Número de processo inválido. Confira os dígitos. | `number` |
| `NOT_FOUND` | Processo não encontrado na base. | - |
| `INVALID_ARGUMENT` | Parâmetro inválido. | argument name |
| `UNAUTHENTICATED` | Faça login para continuar. | - |
| `UNAUTHENTICATED` (bad credentials) | E-mail ou senha inválidos. | - |
| `SUMMARY_UNAVAILABLE` | Não foi possível gerar o resumo agora. | - |
| `RATE_LIMITED` | Muitas tentativas. Aguarde um momento e tente novamente. | - |
| `VALIDATION_FAILED` | Informe um e-mail válido. | `email` |
| `VALIDATION_FAILED` | Este e-mail já está em uso. | `email` |
| `VALIDATION_FAILED` | A senha deve ter de 10 a 72 caracteres. | `password` |

Single source in code: backend `Errors::Messages` (created in task F-10); frontend never hardcodes server messages, it renders `error.message` from the payload except for client-side validation copy listed in the UI spec.

## 3. Operations used by the UI

Located in `frontend/src/graphql/` (created by the Frontend lane, mirrors the spec 05 design): `Lawsuit` query, `GenerateSummary`, `RateSummary`, `Me`, `SignIn`, `SignUp`, `SignOut`. Operation names are part of the contract (used by MSW handlers and Playwright route checks).

## 4. Shared test data (real values from `data/lawsuits_movements.csv`)

### 4.1 Known lawsuit (demo, tests, MSW)

| Field | Value |
|-------|-------|
| Number | `1001399-31.2023.8.26.0070` (digits only: `10013993120238260070`) |
| Forum / court | Foro de Batatais / 2ª Vara Cível |
| Value | raw `10.000` -> amount `10000.00`, formatted `R$ 10.000,00` |
| Authors | 1 |
| Movements | 46 |
| Newest movements (display order) | 2024-06-12 `Certidão de Publicação Expedida` (CSV data row 4997); 2024-06-11 `Remetido ao DJE` (4998); 2024-06-10 `Arquivado Definitivamente` (4999, no content); 2024-06-10 `Certidão de Cartório Expedida` (5000); 2024-06-10 `Ato Ordinatório - Intimação - DJE` (5001) |

The three 2024-06-10 rows prove the tie-break: same date, ordered by ascending data-row index (4999, 5000, 5001).

### 4.2 CNJ vectors

| Input | Expected |
|-------|----------|
| `1001399-31.2023.8.26.0070` | valid, canonical as given |
| `10013993120238260070` | valid, canonical `1001399-31.2023.8.26.0070` |
| `  1001399-31.2023.8.26.0070  ` | valid |
| `1001399-31.2023.8.26.0071` | invalid check digit |
| `1002271-82.2025.8.26.0003` | valid CNJ, **not in the data** -> `NOT_FOUND` |
| `123`, empty, `abc`, 21 digits | invalid format |
| Any of the 100 numbers in the CSV | valid |

### 4.3 Lawsuit shapes for tests

| Purpose | Number | Movements |
|---------|--------|----------:|
| Shortest | `1019112-71.2025.8.26.0224` | 6 |
| Longest (pagination) | `1003790-87.2022.8.26.0071` | 120 |
| Largest text (budget) | `1010953-94.2023.8.26.0100` | 46k+ chars total |

### 4.4 Money and date vectors

| Raw | Parsed |
|-----|--------|
| `10.000` | 10000.00 |
| `13.028,16` | 13028.16 |
| `10.168,2` | 10168.20 |
| `7.650,11` | 7650.11 |
| `5/12/2023` | 2023-12-05 |

### 4.5 Golden set for summary evaluation (spec 04, task A-11)

Chosen from the real data by the planning analysis; the Legal Expert confirms or swaps.

| Lawsuit | Why |
|---------|-----|
| `1019112-71.2025.8.26.0224` | Shortest (6 movements) |
| `1003790-87.2022.8.26.0071` | Longest (120 movements) |
| `1010953-94.2023.8.26.0100` | Most text (budget stress) |
| `1009608-88.2022.8.26.0016` | Settled by agreement (13 movements), archived |
| `1005003-07.2023.8.26.0100` | Claim upheld |
| `1000061-57.2025.8.26.0068` | Claim partly upheld |
| `1030962-43.2024.8.26.0003` | Claim dismissed, with appeal |
| `1024104-25.2021.8.26.0577` | Partly upheld, enforcement phase |
| `1004283-74.2022.8.26.0003` | Archived |
| `1001399-31.2023.8.26.0070` | Demo lawsuit (46 movements) |

### 4.6 Sample summary for MSW and the Fake provider

Fake provider output must be 2 or 3 paragraphs in pt-BR, deterministic, based on lawsuit metadata. Example shape (do not hardcode this exact text; build it from the number, forum, court, value and last movement date):

```
O processo 1001399-31.2023.8.26.0070 tramita na 2ª Vara Cível do Foro de Batatais e discute um valor de R$ 10.000,00.

Ao longo do processo, houve várias etapas: apresentação do pedido, defesa, decisões do juiz e publicações oficiais.

A última movimentação registrada foi em 12/06/2024. Este resumo foi gerado automaticamente a partir dos dados disponíveis.
```

## 5. Environment contract

Variables are defined in [`.env.example`](../../.env.example). Ports: api 3000, web 5173. Single origin in the browser via the Vite proxy for `/graphql`. Cookie name `_lawsuit_session`. Data mount: `./data` read-only at `/data` in the `api` container.

## 6. Stubs-first rule (hotspot files)

To avoid merge conflicts, lane **B1** creates (task F-10, gate G1) every shared Ruby file with the final public shape and stub bodies:

- `Types::QueryType`, `Types::MutationType` declare **all** fields from the contract, each pointing at its own resolver/mutation class (`Resolvers::*`, `Mutations::*`) whose body returns `UNAUTHENTICATED`/`NOT_FOUND`-style placeholders or raises `NotImplementedError`.
- All migrations (lawsuits, movements, summaries, users, sessions, summary_feedbacks) and model files with associations and no logic.
- `Errors::Messages`, `Types::UserErrorType`, `Types::ErrorCode`.
- `Gemfile` with every gem needed by all lanes; `package.json` likewise (lane F1, task F-6).

After G1 a lane only edits the files it owns (see the ownership map in the execution plan). A lane that needs a change in someone else's file asks the owner (execution log) instead of editing it.
