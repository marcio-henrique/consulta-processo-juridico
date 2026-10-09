require "rails_helper"

RSpec.describe "db/seeds.rb" do
  let(:fixture_path) { Rails.root.join("spec/fixtures/files/lawsuits_small.csv").to_s }
  let(:seeds_path) { Rails.root.join("db/seeds.rb").to_s }

  before { stub_const("ENV", ENV.to_hash.merge("LAWSUITS_CSV_PATH" => fixture_path)) }

  it "imports the CSV when the lawsuits table is empty (R5.3)" do
    expect { load seeds_path }.to output(/Lawsuits: 2 created/).to_stdout

    expect(Lawsuit.count).to eq(2)
  end

  it "does nothing when lawsuits already exist (R5.3)" do
    create(:lawsuit)

    expect { load seeds_path }.to output(/already/i).to_stdout
    expect(Lawsuit.count).to eq(1)
  end
end
