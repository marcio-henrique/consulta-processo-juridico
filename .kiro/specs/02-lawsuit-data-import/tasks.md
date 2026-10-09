# Tasks: Lawsuit data import

Lead: Backend. Status: done (verified in Compose: 100 lawsuits / 5,568 movements / 0 skipped; restart does not re-import).

## 4-hour execution board (overrides the hour estimates below)

Schedule and ownership: [EXECUTION-PLAN-4H](../../../docs/plan/EXECUTION-PLAN-4H.md).

| Task | Lane | ⏱ min | After | Parallel with |
|------|------|------:|-------|---------------|
| I-1 `CnjNumber` | B2 | 10 | draft in wave 0, run at G0 | F-10, A-*, U-* |
| I-2 `BrlParser` | B2 | 8 | G0 | F-10 |
| I-3 Models: validations and scopes | B1 | 8 | F-10 | I-4 |
| I-4 CSV fixture use, parsing, grouping | B2 | 15 | F-10, Q-1, I-1, I-2 | L-*, AU-* |
| I-5 Idempotent persistence | B2 | 12 | I-4, I-3 | L-* |
| I-6 Report and rake task | B2 | 6 | I-5 | - |
| I-7 Seeds and entrypoint hook | B2 | 6 | I-6, F-3 | - |
| I-8 Real data smoke test | B2 | 5 | I-7 | - |
| I-9 Docs | B2 | 5 | I-8 | - |

Migrations are created once in F-10 (spec 01); I-3 only adds validations and scopes.

- [x] **I-1. `CnjNumber` helper** (0.75 h)
  - Red: table-driven spec (formatted, digits-only, whitespace, wrong length, letters, bad check digit, segments).
  - Green/Refactor: pure Ruby, no Rails.
  - Include the invalid example `1001399-31.2023.8.26.0071` and the valid challenge example `1002271-82.2025.8.26.0003`.
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5_

- [x] **I-2. `BrlParser` helper** (0.5 h)
  - Red: money and date tables from the requirements, plus error cases. Use `BigDecimal`, never `Float`.
  - _Requirements: 2.1, 2.2, 2.3, 2.4_

- [x] **I-3. Migrations and models** (0.5 h)
  - Create `lawsuits` and `movements` per design.md; model validations; `Movement.display_order` and `.chronological` scopes.
  - Red: model specs for validations and scopes (same-date tie-break by `source_row`).
  - _Requirements: 3.1, 3.2, 3.3, 3.4_

- [x] **I-4. CSV fixture and row parsing/grouping** (0.75 h)
  - Create `spec/fixtures/files/lawsuits_small.csv` covering every edge case in [data-import](../../../docs/domains/data-import.md) section 8.
  - Red: specs for headers check, quoted multi-line content, grouping of interleaved rows, `source_row`, skipped rows with line numbers, conflicting attributes warning.
  - _Requirements: 4.1, 4.2, 4.3, 4.6, 4.7, 4.8, 4.9_

- [x] **I-5. Idempotent persistence** (0.5 h)
  - Red: re-import yields identical state; unchanged lawsuits are not rewritten; transaction rollback on failure.
  - Implement per-lawsuit transaction with upsert + replace movements.
  - _Requirements: 4.4, 4.5_

- [x] **I-6. Report and rake task** (0.25 h)
  - `Imports::Report`; `import:lawsuits[path]`; exit status 1 on fatal errors.
  - _Requirements: 5.1, 5.2, 4.9_

- [x] **I-7. Seeds and container entrypoint** (0.25 h)
  - `db:seed` imports when empty; entrypoint hook from F-3 calls the import when empty.
  - _Requirements: 5.3, 5.4_

- [x] **I-8. Real data smoke test** (0.25 h)
  - `:real_data` spec: 100 lawsuits, 5,568 movements, 0 skipped. Also assert all 100 numbers are valid CNJ.
  - Run it once manually in Compose and paste the report in the PR.
  - _Requirements: 6.1, 6.2_

- [x] **I-9. Docs** (0.25 h)
  - Update [data-import](../../../docs/domains/data-import.md) if behavior differs; update `architecture.md` ER if columns changed; run [finish-delivery-docs](../../../docs/skills/finish-delivery-docs.md).

## Definition of done (spec)
- [x] `docker compose up` on a clean volume imports the CSV automatically; report shows 100 / 5568 / 0 skipped.
- [x] Second start does not re-import (table not empty); manual `import:lawsuits` re-run is a no-op.
- [x] All new code covered; gate green.
