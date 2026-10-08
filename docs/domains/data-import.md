# Domain: Data import

> Contract and rules for loading `data/lawsuits_movements.csv` into the database. Covers challenge FR 1.

## 1. Input file

Path: `data/lawsuits_movements.csv`. UTF-8, header row, RFC 4180 quoting (movement content is multi-line and contains escaped double quotes).

| Column | Type after import | Notes |
|--------|-------------------|-------|
| `lawsuit_number` | `lawsuits.number` | CNJ, unique key of a lawsuit. Repeats once per movement. |
| `lawsuit_forum` | `lawsuits.forum` | e.g. `Foro Regional III - Jabaquara` |
| `lawsuit_court` | `lawsuits.court` | e.g. `2ª Vara Cível` |
| `lawsuit_value` | `lawsuits.value` decimal(15,2) | pt-BR number, see parsing |
| `lawsuit_number_of_authors` | `lawsuits.number_of_authors` int | 1..5 in the data |
| `movement_date` | `movements.occurred_on` date | `d/m/yyyy` (no zero padding) |
| `movement_title` | `movements.title` | 183 distinct titles |
| `movement_content` | `movements.content` text, nullable | Empty in 1,312 rows |

## 2. Profile of the provided file (measured during planning)

| Fact | Value |
|------|-------|
| Data rows | 5,568 |
| Distinct lawsuits | 100 (6 to 120 movements each, avg 55.7) |
| Forums / courts | 19 / 33 |
| Lawsuit attributes consistent across rows of the same lawsuit | yes (0 conflicts) |
| CNJ format and check digit | 100/100 valid; all `8.26` (TJSP) |
| Value range | R$ 2.423,06 to R$ 40.577,90 |
| Date range | 2020-03-05 to 2025-04-26 |
| Empty `movement_content` | 1,312 rows |
| Longest content | 15,264 chars |
| Total chars per lawsuit (title + content) | median ~15.5k, max ~48k |
| Rows of one lawsuit contiguous in the file | **No** (438 breaks) |
| Lawsuits strictly sorted by date DESC in file | **27 of 100** |
| Same-date movement groups | 1,175 |
| Duplicate full rows | 0 |

Consequences: ordering must not depend on file order alone; a tie-breaker (`source_row`) is stored; the importer must group rows by lawsuit.

## 3. Parsing rules

### Money (`lawsuit_value`)

pt-BR: `.` is the thousands separator, `,` is the decimal separator.

| Raw | Parsed |
|-----|--------|
| `10.000` | `10000.00` |
| `13.028,16` | `13028.16` |
| `10.168,2` | `10168.20` |
| `7.650,11` | `7650.11` |

Implementation: strip `.`, replace `,` with `.`, parse with `BigDecimal`. Never use `Float`. Reject empty, negative or non-numeric values.

### Date (`movement_date`)

`d/m/yyyy` parsed with `Date.strptime(raw, '%d/%m/%Y')`. Invalid dates reject the row.

### CNJ number

Parsed with `CnjNumber`. Invalid format or check digit rejects the row (none expected in the provided file).

### Content

Stored as-is, except: normalize `\r\n` to `\n`; `nil` when blank after strip. Do not alter wording.

## 4. Ordering

Display (newest first): `occurred_on DESC, source_row ASC`.
Chronological (for the LLM): `occurred_on ASC, source_row DESC`.

`source_row` is the 1-based index of the data row in the CSV (header excluded). Rationale and evidence: [ADR-0005](../adr/0005-movement-ordering-and-idempotent-import.md).

## 5. Idempotency

The import can run any number of times with the same result.

1. Read the file, group rows by `lawsuit_number`, keeping `source_row`.
2. In **one transaction per lawsuit**: upsert the lawsuit by `number`; delete its movements; bulk insert the new movements.
3. Cached summaries are keyed by `movements_digest`, so unchanged lawsuits keep their summaries and changed ones get new summaries on demand.
4. If a lawsuit's attributes differ between rows, use the first row and count a warning.

Row-level problems are collected, not fatal: the row is skipped and reported.

## 6. Report

The importer returns and prints a report:

```
Import finished in 1.8s
Lawsuits: 100 created, 0 updated, 0 unchanged
Movements: 5568 inserted, 0 deleted
Rows skipped: 0
Warnings: 0
```

Skipped rows and warnings include the CSV line number and reason. Exit code is non-zero only when the file is missing/unreadable or required headers are absent.

## 7. Entry points

| Entry point | Behavior |
|-------------|----------|
| `bin/rails import:lawsuits[path]` | Default path `../data/lawsuits_movements.csv` (configurable via `LAWSUITS_CSV_PATH`) |
| `bin/rails db:seed` | Calls the importer if the `lawsuits` table is empty |
| Docker entrypoint (`api`) | Runs `db:prepare`; imports when the table is empty |

## 8. Test fixtures

`backend/spec/fixtures/files/lawsuits_small.csv`: hand-made, covers: multi-line quoted content, escaped quotes, empty content, thousands-only value, value with 1 decimal digit, same-date movements, interleaved rows of two lawsuits, an invalid CNJ row, an invalid date row, and a conflicting-attribute row.
