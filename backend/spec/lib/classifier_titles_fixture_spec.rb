require "rails_helper"
require "csv"

# Structural check on the classifier_titles fixture itself (not the
# classifier, which doesn't exist until spec 04). Guards against typos and
# titles that don't actually appear in the challenge data.
RSpec.describe "classifier_titles.yml fixture" do
  let(:entries) { YAML.load_file(Rails.root.join("spec/fixtures/classifier_titles.yml")) }
  let(:real_titles) do
    CSV.read(ENV.fetch("LAWSUITS_CSV_PATH", "/data/lawsuits_movements.csv"), headers: true)
      .map { |row| row["movement_title"] }.uniq
  end

  it "has at least 60 entries" do
    expect(entries.size).to be >= 60
  end

  it "only uses the allowed expected values" do
    expect(entries.map { |e| e["expected"] }.uniq).to all(be_in(%w[milestone context noise]))
  end

  it "every title exists in the real CSV" do
    missing = entries.map { |e| e["title"] } - real_titles
    expect(missing).to be_empty
  end
end
