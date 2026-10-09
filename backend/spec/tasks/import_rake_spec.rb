require "rails_helper"
require "rake"

RSpec.describe "import:lawsuits" do
  let(:fixture_path) { Rails.root.join("spec/fixtures/files/lawsuits_small.csv").to_s }
  let(:task) { Rake::Task["import:lawsuits"] }

  before(:all) do
    Rails.application.load_tasks unless Rake::Task.task_defined?("import:lawsuits")
  end

  before { task.reenable }

  it "imports the given path and prints the report (R5.1, R5.2)" do
    expect { task.invoke(fixture_path) }.to output(
      /Import finished in .*\nLawsuits: 2 created, 0 updated, 0 unchanged\nMovements: 8 inserted, 0 deleted\nRows skipped: 2\nWarnings: 2/
    ).to_stdout

    expect(Lawsuit.count).to eq(2)
  end

  it "defaults to LAWSUITS_CSV_PATH (R5.2)" do
    stub_const("ENV", ENV.to_hash.merge("LAWSUITS_CSV_PATH" => fixture_path))

    expect { task.invoke }.to output(/Lawsuits: 2 created/).to_stdout
  end

  it "aborts with status 1 and a clear message when the file is missing (R4.9)" do
    expect { task.invoke("/nonexistent/lawsuits.csv") }
      .to raise_error(SystemExit) { |error| expect(error.status).to eq(1) }
      .and output(/CSV file not found: \/nonexistent\/lawsuits\.csv/).to_stderr
  end
end
