require "rails_helper"
require "rake"

RSpec.describe "summaries:eval" do
  let(:task) { Rake::Task["summaries:eval"] }

  before(:all) do
    Rails.application.load_tasks unless Rake::Task.task_defined?("summaries:eval")
  end

  before { task.reenable }

  it "is defined" do
    expect(Rake::Task.task_defined?("summaries:eval")).to be(true)
  end

  it "refuses to run with the fake provider unless ALLOW_FAKE=1" do
    expect { task.invoke }
      .to raise_error(SystemExit) { |error| expect(error.status).to eq(1) }
      .and output(/fake provider.*ALLOW_FAKE=1/i).to_stderr
  end

  it "runs the requested lawsuits with ALLOW_FAKE=1" do
    lawsuit = create(:lawsuit)
    create(:movement, lawsuit: lawsuit, source_row: 1)
    stub_const("ENV", ENV.to_hash.merge("ALLOW_FAKE" => "1", "LAWSUITS" => lawsuit.number))

    expect { task.invoke }.to output(/#{Regexp.escape(lawsuit.number)}/).to_stdout
    expect(Summary.where(lawsuit: lawsuit).count).to eq(1)
  end
end
