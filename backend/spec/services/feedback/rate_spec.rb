require "rails_helper"

RSpec.describe Feedback::Rate do
  let(:user) { create(:user) }
  let(:summary) { create(:summary) }

  def rate(helpful, as: user, summary_id: summary.id)
    described_class.call(user: as, summary_id: summary_id, helpful: helpful)
  end

  it "creates the vote" do
    result = rate(true)
    expect(result).to be_success
    expect(result.feedback).to have_attributes(summary_id: summary.id, user_id: user.id, helpful: true)
    expect(SummaryFeedback.count).to eq(1)
  end

  it "stores a negative vote" do
    expect(rate(false).feedback.helpful).to be(false)
  end

  it "updates the existing vote instead of creating a second row" do
    rate(true)
    result = rate(false)
    expect(result).to be_success
    expect(result.feedback.helpful).to be(false)
    expect(SummaryFeedback.where(summary: summary, user: user).pluck(:helpful)).to eq([ false ])
  end

  it "is idempotent when the same value is sent repeatedly" do
    3.times { expect(rate(true)).to be_success }
    expect(SummaryFeedback.count).to eq(1)
    expect(SummaryFeedback.first.helpful).to be(true)
  end

  it "accepts the summary id as a string (GraphQL ID)" do
    expect(rate(true, summary_id: summary.id.to_s)).to be_success
  end

  it "keeps the votes of different users independent" do
    other = create(:user)
    rate(true)
    rate(false, as: other)
    expect(SummaryFeedback.find_by(summary: summary, user: user).helpful).to be(true)
    expect(SummaryFeedback.find_by(summary: summary, user: other).helpful).to be(false)
    rate(false)
    expect(SummaryFeedback.find_by(summary: summary, user: other).helpful).to be(false)
  end

  it "keeps votes of different summaries independent" do
    other_summary = create(:summary, lawsuit: summary.lawsuit)
    rate(true)
    rate(false, summary_id: other_summary.id)
    expect(SummaryFeedback.where(user: user).pluck(:helpful)).to match_array([ true, false ])
  end

  it "returns NOT_FOUND for an unknown summary" do
    result = rate(true, summary_id: 0)
    expect(result).not_to be_success
    expect(result.error_code).to eq(:NOT_FOUND)
    expect(SummaryFeedback.count).to eq(0)
  end

  it "returns NOT_FOUND for ids that are not numbers" do
    expect(rate(true, summary_id: "abc").error_code).to eq(:NOT_FOUND)
    expect(rate(true, summary_id: nil).error_code).to eq(:NOT_FOUND)
    expect(rate(true, summary_id: "99999999999999999999999").error_code).to eq(:NOT_FOUND)
  end

  it "leaves one row when two threads rate at the same time" do
    # Rails shares the test transaction's connection between threads, so this
    # proves the upsert path never raises or duplicates; the unique index
    # itself is covered in summary_feedback_spec.
    other = create(:user)
    summary
    threads = [ user, other, user, other ].map do |voter|
      Thread.new do
        ActiveRecord::Base.connection_pool.with_connection { rate(true, as: voter) }
      end
    end
    expect(threads.map(&:value)).to all(be_success)
    expect(SummaryFeedback.where(summary: summary).count).to eq(2)
  end
end
