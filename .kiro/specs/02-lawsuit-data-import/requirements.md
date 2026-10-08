# Requirements: Lawsuit data import

## Introduction

Import `data/lawsuits_movements.csv` into PostgreSQL: lawsuits and their movements. Includes the pure helpers `CnjNumber` (reused by the API) and `BrlParser`. Challenge item: FR 1. Related: [data-import](../../../docs/domains/data-import.md), [lawsuit-lookup](../../../docs/domains/lawsuit-lookup.md) (CNJ rules), [ADR-0005](../../../docs/adr/0005-movement-ordering-and-idempotent-import.md).

## Requirements

### Requirement 1: CNJ number handling

**User Story:** As a developer, I want a single, tested CNJ implementation, so that import and API agree on validity and format.

#### Acceptance Criteria
1. WHEN given a string with 20 digits, formatted or not, and surrounding whitespace, THEN `CnjNumber.parse` SHALL return the canonical `NNNNNNN-DD.AAAA.J.TR.OOOO` form.
2. IF the input does not contain exactly 20 digits after removing non-digit characters, THEN `CnjNumber.parse` SHALL report an invalid-format error.
3. WHEN the check digits do not satisfy `98 - (NNNNNNN AAAA J TR OOOO 00 mod 97)`, THEN `CnjNumber.parse` SHALL report an invalid-check-digit error.
4. THE helper SHALL expose the segments (sequence, check digits, year, justice branch, court, origin).
5. THE helper SHALL NOT depend on Rails.

### Requirement 2: Brazilian number and date parsing

**User Story:** As a developer, I want exact parsing of CSV values, so that no money or date is corrupted.

#### Acceptance Criteria
1. WHEN given `10.000`, `13.028,16`, `10.168,2` or `7.650,11`, THEN `BrlParser.money` SHALL return the exact decimals `10000.00`, `13028.16`, `10168.20` and `7650.11` as `BigDecimal`.
2. IF the money value is blank, negative or not numeric, THEN `BrlParser.money` SHALL raise a parse error.
3. WHEN given `5/12/2023`, THEN `BrlParser.date` SHALL return the date 2023-12-05.
4. IF the date is blank or does not exist (for example `31/02/2023`), THEN `BrlParser.date` SHALL raise a parse error.

### Requirement 3: Schema

**User Story:** As a developer, I want a relational schema with integrity constraints, so that data stays consistent.

#### Acceptance Criteria
1. THE database SHALL have a `lawsuits` table with unique `number`, `forum`, `court`, `value` (decimal 15,2), `number_of_authors`, all required.
2. THE database SHALL have a `movements` table with `lawsuit_id` (foreign key, cascade delete), `occurred_on`, `title`, nullable `content` and required `source_row`.
3. THE `movements` table SHALL have an index on `(lawsuit_id, occurred_on DESC, source_row ASC)`.
4. THE models SHALL validate presence of required fields, `number_of_authors >= 1`, `value >= 0`, and a valid CNJ number.

### Requirement 4: Import behavior

**User Story:** As an operator, I want a safe, repeatable import, so that I can run it any number of times.

#### Acceptance Criteria
1. WHEN the importer reads a CSV, THEN it SHALL handle quoted multi-line fields and escaped double quotes.
2. THE importer SHALL group rows by lawsuit number even when rows of one lawsuit are not contiguous.
3. THE importer SHALL store for each movement the 1-based CSV data-row index as `source_row`.
4. WHEN the same file is imported again, THEN the final database state SHALL be identical and no duplicate rows SHALL exist.
5. WHEN the importer processes a lawsuit, THEN it SHALL upsert the lawsuit and replace its movements within one transaction.
6. IF a row has an invalid CNJ number, money value, date or missing required column, THEN the importer SHALL skip that row, continue, and report the CSV line number and reason.
7. IF rows of the same lawsuit disagree on lawsuit attributes, THEN the importer SHALL use the first row and count a warning.
8. WHEN `movement_content` is blank, THEN the importer SHALL store `NULL`; otherwise it SHALL store the text with `\r\n` normalized to `\n` and otherwise unchanged.
9. IF the file is missing, unreadable or lacks a required header, THEN the importer SHALL fail with a clear message and a non-zero exit status.

### Requirement 5: Report and entry points

**User Story:** As an operator, I want a clear result and easy commands.

#### Acceptance Criteria
1. WHEN an import finishes, THEN the system SHALL print lawsuits created/updated/unchanged, movements inserted/deleted, rows skipped and warnings.
2. THE system SHALL provide `bin/rails import:lawsuits[path]`, defaulting to `LAWSUITS_CSV_PATH`.
3. WHEN `db:seed` runs and the `lawsuits` table is empty, THEN the importer SHALL run.
4. WHEN the `api` container starts and the `lawsuits` table is empty, THEN the importer SHALL run before the server accepts requests.

### Requirement 6: Real data check

**User Story:** As a reviewer, I want proof that the real file loads completely.

#### Acceptance Criteria
1. WHEN the real CSV is imported into an empty database, THEN the database SHALL contain 100 lawsuits and 5,568 movements and zero skipped rows.
2. THE real-file test SHALL be skipped with a clear message if the file is not present.
