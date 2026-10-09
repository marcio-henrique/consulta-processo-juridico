require "rails_helper"
require "csv"
require "tmpdir"

RSpec.describe Imports::LawsuitsCsv do
  let(:fixture_path) { Rails.root.join("spec/fixtures/files/lawsuits_small.csv").to_s }
  let(:l1) { "1001399-31.2023.8.26.0070" }
  let(:l2) { "1019112-71.2025.8.26.0224" }
  let(:header) do
    %w[lawsuit_number lawsuit_forum lawsuit_court lawsuit_value lawsuit_number_of_authors
       movement_date movement_title movement_content]
  end

  around do |example|
    Dir.mktmpdir("lawsuits_csv_spec") do |dir|
      @tmp_dir = dir
      example.run
    end
  end

  # Builds a CSV row with sensible defaults; override per example.
  def row(number: l1, forum: "Foro de Batatais", court: "2ª Vara Cível", value: "10.000",
          authors: "1", date: "10/6/2024", title: "Movimento", content: "Texto")
    [ number, forum, court, value, authors, date, title, content ]
  end

  def csv_file(*rows, headers: header, name: "lawsuits.csv")
    path = File.join(@tmp_dir, name)
    File.write(path, CSV.generate { |csv| csv << headers if headers; rows.each { |r| csv << r } })
    path
  end

  def import(path) = described_class.call(path)

  describe "importing the documented fixture" do
    subject!(:report) { import(fixture_path) }

    it "groups interleaved rows into two lawsuits (R4.2)" do
      expect(Lawsuit.order(:number).pluck(:number)).to eq([ l1, l2 ])
      expect(report).to have_attributes(lawsuits_created: 2, lawsuits_updated: 0, lawsuits_unchanged: 0)
    end

    it "stores lawsuit attributes with exact decimals" do
      expect(Lawsuit.find_by!(number: l1)).to have_attributes(
        forum: "Foro de Batatais", court: "2ª Vara Cível", value: BigDecimal("10000.00"), number_of_authors: 1
      )
      expect(Lawsuit.find_by!(number: l2)).to have_attributes(value: BigDecimal("13028.16"), number_of_authors: 2)
    end

    it "stores the 1-based data-row index as source_row, gaps included (R4.3)" do
      expect(Lawsuit.find_by!(number: l1).movements.order(:source_row).pluck(:source_row)).to eq([ 1, 3, 5, 7 ])
      expect(Lawsuit.find_by!(number: l2).movements.order(:source_row).pluck(:source_row)).to eq([ 2, 4, 6, 10 ])
      expect(report.movements_inserted).to eq(8)
    end

    it "keeps multi-line quoted content unchanged (R4.1)" do
      movement = Movement.find_by!(title: "Ato Ordinatório - Intimação - DJE")

      expect(movement.content).to eq("Relação: 0100/2024\nData da Publicação: 11/06/2024")
      expect(movement.occurred_on).to eq(Date.new(2024, 6, 10))
    end

    it "keeps escaped double quotes (R4.1)" do
      content = Movement.find_by!(title: "Juntada de Petição").content

      expect(content).to eq(
        "Petição com múltiplas linhas.\nSegunda linha do texto.\nLinha com \"aspas escapadas\" dentro do conteúdo."
      )
    end

    it "stores NULL for blank content (R4.8)" do
      expect(Movement.find_by!(title: "Arquivado Definitivamente").content).to be_nil
    end

    it "skips invalid rows and reports their CSV line number and reason (R4.6)" do
      expect(report.rows_skipped).to eq(2)
      expect(report.skipped.map(&:line)).to eq([ 12, 13 ])
      expect(report.skipped[0].message).to match(/movement_date/)
      expect(report.skipped[1].message).to match(/lawsuit_number/)
      expect(Movement.where(title: "Movimentação com data inválida")).to be_empty
    end

    it "uses the first row's attributes and warns on conflicts (R4.7)" do
      expect(Lawsuit.find_by!(number: l2).forum).to eq("Foro de Guarulhos")
      # Line 10 carries the "10.168,2" value (different from the lawsuit's 13.028,16);
      # line 14 carries the divergent forum.
      expect(report.warnings.map(&:line)).to eq([ 10, 14 ])
      expect(report.warnings[0].message).to match(/lawsuit_value/)
      expect(report.warnings[1].message).to match(/lawsuit_forum/)
      expect(Lawsuit.find_by!(number: l2).value).to eq(BigDecimal("13028.16"))
      expect(Movement.where(title: "Linha com atributos conflitantes")).to exist
    end

    it "records the duration" do
      expect(report.duration).to be_a(Float)
    end
  end

  describe "content normalization (R4.8)" do
    it "normalizes CRLF to LF and leaves everything else unchanged" do
      import(csv_file(row(content: "linha 1\r\nlinha 2\r\n  recuo  ")))

      expect(Movement.sole.content).to eq("linha 1\nlinha 2\n  recuo  ")
    end

    it "stores NULL for whitespace-only content" do
      import(csv_file(row(content: "  \n ")))

      expect(Movement.sole.content).to be_nil
    end
  end

  describe "row validation (R4.6)" do
    it "skips a row with a missing required value and keeps the rest" do
      path = csv_file(row(title: "Ok"), row(forum: ""), row(title: ""), row(authors: "0"), row(authors: "x"),
                      row(value: "-1"), row(court: nil))
      report = import(path)

      expect(Movement.pluck(:title)).to eq([ "Ok" ])
      expect(report.skipped.map(&:line)).to eq([ 3, 4, 5, 6, 7, 8 ])
      expect(report.skipped.map(&:message)).to match([
        /lawsuit_forum/, /movement_title/, /lawsuit_number_of_authors/, /lawsuit_number_of_authors/,
        /lawsuit_value/, /lawsuit_court/
      ])
    end

    it "does not create a lawsuit whose rows were all skipped" do
      import(csv_file(row(date: "31/02/2023")))

      expect(Lawsuit.count).to eq(0)
    end

    it "ignores blank lines without shifting later line numbers or source_row" do
      path = File.join(@tmp_dir, "blank.csv")
      File.write(path, [ header.join(","), "", row.join(","), "", row(date: "xx").join(",") ].join("\n"))
      report = import(path)

      expect(Movement.pluck(:source_row)).to eq([ 1 ])
      expect(report.skipped.map(&:line)).to eq([ 5 ])
    end
  end

  describe "idempotency (R4.4, R4.5)" do
    it "leaves identical state and rewrites nothing when re-importing the same file" do
      import(fixture_path)
      snapshot = -> { [ Lawsuit.order(:number).pluck(:id, :updated_at), Movement.order(:id).pluck(:id, :lawsuit_id, :source_row, :updated_at) ] }
      before = snapshot.call

      report = import(fixture_path)

      expect(snapshot.call).to eq(before)
      expect(report).to have_attributes(
        lawsuits_created: 0, lawsuits_updated: 0, lawsuits_unchanged: 2, movements_inserted: 0, movements_deleted: 0
      )
      expect(Lawsuit.count).to eq(2)
      expect(Movement.count).to eq(8)
    end

    it "replaces movements of a lawsuit whose content changed and leaves others alone" do
      import(csv_file(row(number: l1, title: "A"), row(number: l2, title: "B", forum: "Foro de Guarulhos")))
      untouched_id = Lawsuit.find_by!(number: l2).movements.sole.id

      report = import(csv_file(row(number: l1, title: "A", content: "novo"),
                               row(number: l2, title: "B", forum: "Foro de Guarulhos")))

      expect(Lawsuit.find_by!(number: l1).movements.sole.content).to eq("novo")
      expect(Lawsuit.find_by!(number: l2).movements.sole.id).to eq(untouched_id)
      expect(report).to have_attributes(
        lawsuits_created: 0, lawsuits_updated: 1, lawsuits_unchanged: 1, movements_inserted: 1, movements_deleted: 1
      )
    end

    it "deletes movements that no longer exist in the file" do
      import(csv_file(row(title: "A"), row(title: "B")))
      report = import(csv_file(row(title: "A")))

      expect(Movement.pluck(:title)).to eq([ "A" ])
      expect(report).to have_attributes(movements_inserted: 1, movements_deleted: 2, lawsuits_updated: 1)
    end

    it "updates lawsuit attributes without touching unchanged movements" do
      import(csv_file(row(value: "10.000")))
      movement_id = Movement.sole.id

      report = import(csv_file(row(value: "12.500,50")))

      expect(Lawsuit.sole.value).to eq(BigDecimal("12500.50"))
      expect(Movement.sole.id).to eq(movement_id)
      expect(report).to have_attributes(lawsuits_updated: 1, movements_inserted: 0, movements_deleted: 0)
    end

    it "does not touch other tables, such as summaries" do
      import(csv_file(row))
      summary = create(:summary, lawsuit: Lawsuit.sole)

      import(csv_file(row(content: "changed")))

      expect(Summary.find(summary.id)).to be_present
    end

    it "processes lawsuits sorted by number, whatever the file order" do
      import(csv_file(row(number: l2, forum: "Foro de Guarulhos"), row(number: l1)))

      expect(Lawsuit.order(:id).pluck(:number)).to eq([ l1, l2 ])
    end
  end

  describe "transactions (R4.5)" do
    it "rolls back the failing lawsuit, reports its rows as skipped, and continues" do
      calls = 0
      allow(Movement).to receive(:insert_all).and_wrap_original do |original, *args, **kwargs|
        calls += 1
        raise ActiveRecord::StatementInvalid, "boom" if calls == 1

        original.call(*args, **kwargs)
      end

      report = import(csv_file(row(number: l1), row(number: l1, title: "Outro"), row(number: l2, forum: "Foro de Guarulhos")))

      expect(Lawsuit.pluck(:number)).to eq([ l2 ])
      expect(Movement.count).to eq(1)
      expect(report.lawsuits_created).to eq(1)
      expect(report.skipped.map(&:line)).to eq([ 2, 3 ])
      expect(report.skipped.first.message).to include(l1, "boom")
      expect(report.movements_inserted).to eq(1)
    end

    it "keeps the previous movements when replacing fails" do
      import(csv_file(row(title: "Antigo")))
      allow(Movement).to receive(:insert_all).and_raise(ActiveRecord::StatementInvalid, "boom")

      report = import(csv_file(row(title: "Novo")))

      expect(Movement.pluck(:title)).to eq([ "Antigo" ])
      expect(report.rows_skipped).to eq(1)
      expect(report).to have_attributes(movements_deleted: 0, lawsuits_updated: 0)
    end
  end

  describe "fatal errors (R4.9)" do
    it "fails when the file does not exist" do
      expect { import(File.join(@tmp_dir, "missing.csv")) }
        .to raise_error(Imports::FatalError, /not found/)
    end

    it "fails when the path is a directory" do
      expect { import(@tmp_dir) }.to raise_error(Imports::FatalError, /not (a )?readable|not a file/i)
    end

    it "fails when the path is blank" do
      expect { import("") }.to raise_error(Imports::FatalError, /path/i)
    end

    it "fails when a required header is missing, naming it" do
      path = csv_file(row.first(7), headers: header - [ "movement_title" ])

      expect { import(path) }.to raise_error(Imports::FatalError, /movement_title/)
    end

    it "fails on an empty file" do
      path = File.join(@tmp_dir, "empty.csv")
      File.write(path, "")

      expect { import(path) }.to raise_error(Imports::FatalError, /header/i)
    end

    it "fails on malformed CSV before changing the database" do
      path = File.join(@tmp_dir, "bad.csv")
      File.write(path, "#{header.join(',')}\n#{row.first(3).join(',')},\"unterminated\n")

      expect { import(path) }.to raise_error(Imports::FatalError, /malformed/i)
      expect(Lawsuit.count).to eq(0)
    end

    it "fails on invalid UTF-8" do
      path = File.join(@tmp_dir, "latin1.csv")
      File.binwrite(path, "#{header.join(',')}\n1001399-31.2023.8.26.0070,Foro,Vara,10.000,1,10/6/2024,Peti\xE7\xE3o,x\n".b)

      expect { import(path) }.to raise_error(Imports::FatalError, /utf-8|encoding/i)
    end

    it "accepts a UTF-8 BOM" do
      path = File.join(@tmp_dir, "bom.csv")
      File.write(path, "\uFEFF#{header.join(',')}\n#{row.join(',')}\n")

      expect(import(path).movements_inserted).to eq(1)
    end
  end

  describe ".default_path" do
    it "uses LAWSUITS_CSV_PATH when set" do
      stub_const("ENV", ENV.to_hash.merge("LAWSUITS_CSV_PATH" => "/somewhere/else.csv"))

      expect(described_class.default_path).to eq("/somewhere/else.csv")
    end

    it "falls back to data/lawsuits_movements.csv next to the backend directory" do
      stub_const("ENV", ENV.to_hash.except("LAWSUITS_CSV_PATH"))

      expect(described_class.default_path).to eq(File.expand_path("../data/lawsuits_movements.csv", Rails.root))
    end
  end
end
