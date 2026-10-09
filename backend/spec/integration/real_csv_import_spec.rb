require "rails_helper"

# Imports the real challenge file (R6). Skipped when the file is absent so the
# suite stays runnable in environments without the data directory.
RSpec.describe "Real CSV import", :real_data do
  let(:csv_path) { ENV.fetch("LAWSUITS_CSV_PATH", "/data/lawsuits_movements.csv") }

  before do
    skip "Real CSV not present at #{csv_path}" unless File.exist?(csv_path)
  end

  it "loads 100 lawsuits and 5,568 movements with zero skipped rows (R6.1)" do
    report = Imports::LawsuitsCsv.call(csv_path)

    expect(Lawsuit.count).to eq(100)
    expect(Movement.count).to eq(5568)
    expect(report).to have_attributes(
      lawsuits_created: 100, movements_inserted: 5568, rows_skipped: 0, warnings: []
    )
    expect(Lawsuit.pluck(:number).map { |number| CnjNumber.parse(number) }).to all(be_valid)
  end

  it "is a no-op when imported a second time (R4.4)" do
    Imports::LawsuitsCsv.call(csv_path)

    report = Imports::LawsuitsCsv.call(csv_path)

    expect(report).to have_attributes(
      lawsuits_created: 0, lawsuits_updated: 0, lawsuits_unchanged: 100, movements_inserted: 0, movements_deleted: 0
    )
    expect(Movement.count).to eq(5568)
  end
end
