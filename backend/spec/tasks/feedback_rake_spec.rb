require "rails_helper"
require "rake"

RSpec.describe "feedback:report" do
  let(:task) { Rake::Task["feedback:report"] }

  before(:all) do
    Rails.application.load_tasks unless Rake::Task.task_defined?("feedback:report")
  end

  before { task.reenable }

  def vote(summary, helpful, user: create(:user))
    create(:summary_feedback, summary: summary, user: user, helpful: helpful)
  end

  it "says so when there are no votes" do
    create(:summary)
    expect { task.invoke }.to output("No feedback votes yet.\n").to_stdout
  end

  it "says so when there are no summaries at all" do
    expect { task.invoke }.to output("No feedback votes yet.\n").to_stdout
  end

  it "prints one row per prompt version and model with counts and the helpful rate" do
    v1_a = create(:summary, prompt_version: "v1", model: "model-a")
    v1_b = create(:summary, prompt_version: "v1", model: "model-a")
    v2 = create(:summary, prompt_version: "v2", model: "model-b")
    create(:summary, prompt_version: "v2", model: "model-b") # never voted on
    2.times { vote(v1_a, true) }
    vote(v1_a, false)
    vote(v1_b, true)
    vote(v2, false)

    output = capture_stdout { task.invoke }
    lines = output.lines.map(&:split)

    expect(lines[0]).to eq(%w[prompt_version model summaries votes helpful not_helpful helpful_rate])
    expect(lines[1]).to eq(%w[v1 model-a 2 4 3 1 75.0%])
    expect(lines[2]).to eq(%w[v2 model-b 2 1 0 1 0.0%])
  end

  it "shows a dash as rate for a group without votes" do
    create(:summary, prompt_version: "v1", model: "voted").tap { |s| vote(s, true) }
    create(:summary, prompt_version: "v2", model: "silent")
    lines = capture_stdout { task.invoke }.lines.map(&:split)
    expect(lines.last).to eq(%w[v2 silent 1 0 0 0 -])
  end

  it "never prints user identifiers or emails" do
    user = create(:user, email: "secret.person@example.com")
    summary = create(:summary)
    vote(summary, true, user: user)
    output = capture_stdout { task.invoke }
    expect(output).not_to include("secret.person")
    expect(output).not_to include("@")
    expect(output).not_to match(/user/i)
  end

  def capture_stdout
    original = $stdout
    $stdout = StringIO.new
    yield
    $stdout.string
  ensure
    $stdout = original
  end
end
