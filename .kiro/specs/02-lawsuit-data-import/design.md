# Design: Lawsuit data import

## Overview

Pure helpers (`CnjNumber`, `BrlParser`) feed `Imports::LawsuitsCsv`, which parses, groups and persists. A rake task and the container entrypoint call it.

## Components

| Component | Location | Responsibility |
|-----------|----------|----------------|
| `CnjNumber` | `app/lib/cnj_number.rb` | `parse(str) -> Result`, canonical string, segments, check digit calc |
| `BrlParser` | `app/lib/brl_parser.rb` | `money(str) -> BigDecimal`, `date(str) -> Date`; raises `BrlParser::ParseError` |
| `Lawsuit`, `Movement` | `app/models/` | Validations, associations, `Movement.display_order`, `Movement.chronological` scopes |
| `Imports::LawsuitsCsv` | `app/services/imports/lawsuits_csv.rb` | `call(path) -> Imports::Report` |
| `Imports::Report` | `app/services/imports/report.rb` | Counters, `skipped` and `warnings` entries, `to_s` |
| Rake | `lib/tasks/import.rake` | `import:lawsuits[path]`, prints report, exit status |
| Seeds / entrypoint | `db/seeds.rb`, `bin/docker-entrypoint` | Import when `Lawsuit.none?` |

## Interfaces

```ruby
CnjNumber.parse("1001399-31.2023.8.26.0070")
# => #<CnjNumber::Result valid?=true formatted="1001399-31.2023.8.26.0070" segments={...}>
CnjNumber.parse("123")
# => Result valid?=false error=:invalid_format

BrlParser.money("13.028,16") # => 0.1302816e5 (BigDecimal)
BrlParser.date("5/12/2023")  # => Date.new(2023, 12, 5)
```

Check digit (digits-only string `d`): `98 - ((d[0,7] + d[9,4] + d[13] + d[14,2] + d[16,4] + "00").to_i % 97)`, zero-padded to 2 chars. Implementation note: build the number from segments, not from string offsets of the formatted form.

## Data model

```ruby
create_table :lawsuits do |t|
  t.string  :number, null: false
  t.string  :forum,  null: false
  t.string  :court,  null: false
  t.decimal :value,  precision: 15, scale: 2, null: false
  t.integer :number_of_authors, null: false
  t.timestamps
end
add_index :lawsuits, :number, unique: true

create_table :movements do |t|
  t.references :lawsuit, null: false, foreign_key: { on_delete: :cascade }
  t.date    :occurred_on, null: false
  t.string  :title, null: false
  t.text    :content
  t.integer :source_row, null: false
  t.timestamps
end
add_index :movements, [:lawsuit_id, :occurred_on, :source_row], name: "index_movements_on_lawsuit_and_order"
```

Note: the composite index is `(lawsuit_id, occurred_on, source_row)`; PostgreSQL can scan it backwards, so the DESC/ASC mix is served well enough for 120-row sets. Do not add a custom DESC index unless a query plan shows a need.

## Import algorithm

```
1. Open CSV with headers (CSV.foreach with liberal_parsing false, encoding UTF-8).
2. Validate required headers; fail fast otherwise.
3. For each data row (index i from 1; csv line = i + 1): parse CNJ, money, date, integer authors;
   on error -> report.skip(line, reason); else append to groups[number] with source_row = i.
4. For each lawsuit group (sorted by number for determinism):
   a. Attributes from the first row; if later rows differ -> report.warn.
   b. transaction do
        lawsuit = Lawsuit.find_or_initialize_by(number:); assign; save! (track created/updated/unchanged)
        lawsuit.movements.delete_all
        Movement.insert_all(rows)          # bulk
      end
5. Return report.
```

"Unchanged" is true when lawsuit attributes did not change and the movements digest (date|title|content in order) matches the stored one; the movements are then left untouched to avoid pointless churn. (Implementation may compute the digest in SQL or Ruby; keep simple.)

## Error handling

| Case | Behavior |
|------|----------|
| Row-level parse error | Skipped, reported with line and reason |
| DB error in one lawsuit | Transaction rolls back that lawsuit; reported as skipped group; import continues |
| Missing file / headers | Raise `Imports::FatalError`; rake prints message and exits 1 |

## Testing strategy

- `spec/lib/cnj_number_spec.rb`: valid formatted, digits-only, whitespace, 19/21 digits, letters, bad check digit, segments; all 100 real numbers valid (table from the CSV via fixture list).
- `spec/lib/brl_parser_spec.rb`: table of money and date cases, including error cases.
- `spec/services/imports/lawsuits_csv_spec.rb` with `lawsuits_small.csv`: multi-line quotes, escaped quotes, empty content, interleaved rows, tie-break `source_row`, bad rows skipped with lines, conflicting attributes warning, re-run idempotent (counts and `updated_at` unchanged for unchanged lawsuits), transaction rollback on injected failure.
- `spec/tasks/import_rake_spec.rb`: exit status and output.
- `spec/integration/real_csv_import_spec.rb`: tagged `:real_data`; imports `/data/lawsuits_movements.csv` (or `LAWSUITS_CSV_PATH`) and asserts 100 / 5,568 / 0 skipped; `skip` when absent.
