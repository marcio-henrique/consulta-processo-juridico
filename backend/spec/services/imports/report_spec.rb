require "rails_helper"

RSpec.describe Imports::Report do
  subject(:report) { described_class.new }

  it "starts with every counter at zero" do
    expect(report).to have_attributes(
      lawsuits_created: 0, lawsuits_updated: 0, lawsuits_unchanged: 0,
      movements_inserted: 0, movements_deleted: 0, rows_skipped: 0, warnings: []
    )
  end

  it "records skipped rows with line and reason (R4.6)" do
    report.skip(line: 12, reason: "invalid date")

    expect(report.rows_skipped).to eq(1)
    expect(report.skipped.first).to have_attributes(line: 12, message: "invalid date")
  end

  it "records warnings with line and message (R4.7)" do
    report.warn(line: 14, message: "forum differs")

    expect(report.warnings.size).to eq(1)
    expect(report.warnings.first).to have_attributes(line: 14, message: "forum differs")
  end

  describe "#to_s (R5.1)" do
    it "prints the summary in the documented format" do
      report.lawsuits_created = 100
      report.movements_inserted = 5568
      report.duration = 1.84

      expect(report.to_s).to eq(<<~TEXT.chomp)
        Import finished in 1.8s
        Lawsuits: 100 created, 0 updated, 0 unchanged
        Movements: 5568 inserted, 0 deleted
        Rows skipped: 0
        Warnings: 0
      TEXT
    end

    it "lists skipped rows and warnings with their line numbers" do
      report.skip(line: 12, reason: "invalid date")
      report.warn(line: 14, message: "forum differs")

      expect(report.to_s).to include("Rows skipped: 1", "Warnings: 1")
      expect(report.to_s).to include("  skipped line 12: invalid date")
      expect(report.to_s).to include("  warning line 14: forum differs")
    end
  end
end
