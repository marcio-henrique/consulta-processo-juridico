# Domain: Lawsuit lookup

> How a user finds a lawsuit and how the lawsuit page is composed. Covers challenge FR 2, 3 and part of FR 4.

## 1. CNJ number

Format: `NNNNNNN-DD.AAAA.J.TR.OOOO` (20 digits), defined by CNJ Resolution 65/2008.

| Segment | Meaning | Example (`1002271-82.2025.8.26.0003`) |
|---------|---------|----------------------------------------|
| `NNNNNNN` | Sequential number in the unit/year | `1002271` |
| `DD` | Check digits | `82` |
| `AAAA` | Year the lawsuit was filed | `2025` |
| `J` | Branch of the judiciary (`8` = State Justice) | `8` |
| `TR` | Court (`26` = TJSP) | `26` |
| `OOOO` | Origin unit (forum/district code) | `0003` (Foro Regional III - Jabaquara) |

### Check digit algorithm (ISO 7064 mod 97-10)

```
remainder = int(NNNNNNN + AAAA + J + TR + OOOO + "00") % 97
DD        = 98 - remainder          # zero-padded to 2 digits
```

All 100 numbers in the CSV pass this check (verified during planning). The server rejects numbers that fail it with `INVALID_CNJ`.

### Normalization (server and client)

1. Trim whitespace.
2. Remove everything that is not a digit.
3. If the result has exactly 20 digits, reformat to the canonical mask. Otherwise it is invalid (`INVALID_CNJ`).
4. Verify the check digit.

Users may paste `10022718220258260003` or the formatted form; both work. The client mirrors the mask and format validation for fast feedback (`src/lib/cnj.ts`), but the server is authoritative.

## 2. Pages

### Home (authenticated)

Only: a single CNJ input, a "Consultar" button, and the minimal app header (logo, user, sign out). No other content (challenge FR 2).

| State | Behavior |
|-------|----------|
| Empty submit | Inline error "Informe o número do processo." |
| Invalid format / check digit | Inline error "Número de processo inválido. Confira os dígitos." |
| Valid | Navigate to `/processos/:number` |

### Lawsuit page `/processos/:number`

Section order (mirrors e-SAJ, plus the summary):

1. **Header**: CNJ number (large).
2. **Process data**: Foro, Vara, Valor da ação, Número de autores.
3. **Resumo do processo (IA)**: the summary card (see [ai-summary](ai-summary.md)).
4. **Movimentações**: table `Data | Movimentação`, newest first.

| State | Behavior |
|-------|----------|
| Loading | Skeletons for data and movements |
| Not found | "Processo não encontrado na base." with a link back to the home page. Explain that only imported lawsuits are available. |
| Invalid number in URL | Same as not found, with the invalid-number message |
| Summary loading | Skeleton in the summary card only; rest of the page is usable |
| Summary failed | Message "Não foi possível gerar o resumo agora." + retry button |

### e-SAJ field mapping

Reference page saved in `data/html_link_portal/`. The CSV only supplies part of the e-SAJ fields.

| e-SAJ field | In CSV? | Our UI |
|-------------|:-------:|--------|
| Número do processo | yes (`lawsuit_number`) | Header |
| Situação (e.g. "Extinto") | no | **Not shown** (never invented) |
| Classe / Assunto / Juiz / Controle / Área / Distribuição | no | **Not shown** |
| Foro | yes (`lawsuit_forum`) | Process data |
| Vara | yes (`lawsuit_court`) | Process data |
| Valor da ação | yes (`lawsuit_value`) | Process data, `R$ 8.000,00` |
| Partes | only the count (`lawsuit_number_of_authors`) | "Número de autores" |
| Movimentações (Data, Tipo, content) | yes | Movements table |

The first movement ("Distribuído Livremente...") gives the distribution date; it may be shown as "Distribuição" derived from data, labeled as such. This is optional polish, not a requirement.

## 3. Movements table

- Real `<table>` with `<caption>` (visually hidden), `<th scope="col">`.
- Columns: **Data** (`dd/mm/aaaa`) and **Movimentação** (title in bold; content below in smaller, muted text).
- Ordering: `occurred_on DESC, source_row ASC` ([ADR-0005](../adr/0005-movement-ordering-and-idempotent-import.md)).
- Content keeps line breaks (`white-space: pre-wrap`), is rendered as text, and is collapsed after ~300 characters with a "Ver mais" button (`aria-expanded`).
- Movements without content show the title only.
- Initial page size 25, "Carregar mais" fetches the next page (cursor pagination). Max movements in the data is 120.

## 4. Formatting rules

| Value | Rule |
|-------|------|
| Money | `Intl.NumberFormat('pt-BR', {style:'currency', currency:'BRL'})` |
| Date | `dd/mm/aaaa`, always from an ISO date string, no timezone shifting (parse as a plain date) |
| Numbers | pt-BR locale |

## 5. Errors

| Code | When | UI |
|------|------|----|
| `INVALID_CNJ` | Format or check digit fails | Inline error on the form / not-found page |
| `NOT_FOUND` | Valid CNJ but not in the database | Not-found state |
| `UNAUTHENTICATED` | No valid session | Redirect to login, then back |

## 6. Acceptance examples

| Input | Expected |
|-------|----------|
| `1001399-31.2023.8.26.0070` | Found; Foro de Batatais; 2ª Vara Cível; R$ 10.000,00 |
| `10013993120238260070` | Same as above (normalized) |
| `1001399-31.2023.8.26.0071` | `INVALID_CNJ` (check digit) |
| `1002271-82.2025.8.26.0003` | The challenge statement's example. Valid CNJ (check digit passes) but **not present in the provided CSV** (verified), so it must return `NOT_FOUND`. Do not use it as a "found" example in tests, demos or docs. |
