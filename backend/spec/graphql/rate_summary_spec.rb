require "rails_helper"

RSpec.describe "Summary feedback GraphQL operations", type: :graphql do
  let(:number) { "1001399-31.2023.8.26.0070" }
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let!(:lawsuit) do
    create(:lawsuit, number: number).tap { |record| create(:movement, lawsuit: record, source_row: 1) }
  end
  let!(:summary) do
    create(:summary, lawsuit: lawsuit, movements_digest: Summaries::Digest.call(lawsuit.movements),
      prompt_version: Summaries::PromptBuilder::PROMPT_VERSION)
  end

  let(:mutation) do
    <<~GQL
      mutation Rate($summaryId: ID!, $helpful: Boolean!) {
        rateSummary(summaryId: $summaryId, helpful: $helpful) {
          feedback { summaryId helpful }
          errors { code message field }
        }
      }
    GQL
  end

  let(:query) do
    <<~GQL
      query Lawsuit($number: String!) {
        lawsuit(number: $number) {
          lawsuit { latestSummary { id myFeedback } }
        }
      }
    GQL
  end

  def rate(helpful, as: user, id: summary.id.to_s)
    execute_graphql(mutation, variables: { summaryId: id, helpful: helpful }, user: as)
  end

  def my_feedback(as: user)
    result = execute_graphql(query, variables: { number: number }, user: as)
    result.dig(:data, :lawsuit, :lawsuit, :latestSummary, :myFeedback)
  end

  describe "Mutation.rateSummary" do
    it "creates the vote and returns it with an empty errors list" do
      result = rate(true)
      expect(result[:errors]).to be_nil
      expect(result.dig(:data, :rateSummary)).to eq(
        feedback: { summaryId: summary.id.to_s, helpful: true }, errors: []
      )
      expect(SummaryFeedback.count).to eq(1)
    end

    it "changes the vote when the same user rates again" do
      rate(true)
      expect(rate(false).dig(:data, :rateSummary, :feedback, :helpful)).to be(false)
      expect(SummaryFeedback.count).to eq(1)
    end

    it "is idempotent for the same value" do
      2.times { expect(rate(true).dig(:data, :rateSummary, :errors)).to eq([]) }
      expect(SummaryFeedback.count).to eq(1)
    end

    it "does not touch the votes of other users" do
      rate(true, as: other_user)
      rate(false)
      expect(SummaryFeedback.find_by(user: other_user).helpful).to be(true)
    end

    it "returns NOT_FOUND for an unknown summary" do
      payload = rate(true, id: "0").dig(:data, :rateSummary)
      expect(payload).to eq(
        feedback: nil,
        errors: [ { code: "NOT_FOUND", message: "Processo não encontrado na base.", field: nil } ]
      )
    end

    it "returns UNAUTHENTICATED to anonymous callers without writing" do
      payload = rate(true, as: nil).dig(:data, :rateSummary)
      expect(payload[:errors].first).to include(code: "UNAUTHENTICATED")
      expect(payload[:feedback]).to be_nil
      expect(SummaryFeedback.count).to eq(0)
    end
  end

  describe "Summary.myFeedback" do
    it "is null before the user votes" do
      expect(my_feedback).to be_nil
    end

    it "is true after a helpful vote and false after a not helpful vote" do
      rate(true)
      expect(my_feedback).to be(true)
      rate(false)
      expect(my_feedback).to be(false)
    end

    it "shows each user only their own vote" do
      rate(true, as: user)
      rate(false, as: other_user)
      expect(my_feedback(as: user)).to be(true)
      expect(my_feedback(as: other_user)).to be(false)
      expect(my_feedback(as: create(:user))).to be_nil
    end

    it "is also available on the generateSummary payload" do
      rate(true)
      allow(Llm::Client).to receive(:build).and_return(Llm::Client.new(provider: Llm::Providers::Fake.new, model: "fake-v1"))
      result = execute_graphql(<<~GQL, variables: { n: number }, user: user)
        mutation($n: String!) { generateSummary(lawsuitNumber: $n) { summary { myFeedback } errors { code } } }
      GQL
      expect(result.dig(:data, :generateSummary, :summary, :myFeedback)).to be(true)
    end

    it "exposes no field with other users' votes or aggregates" do
      names = Types::SummaryType.fields.keys + Types::SummaryFeedbackType.fields.keys
      expect(names).to match_array(%w[id body generatedAt myFeedback summaryId helpful])
    end

    it "batches the votes of many summaries into one query" do
      summaries = create_list(:summary, 3, lawsuit: lawsuit)
      create(:summary_feedback, summary: summaries[0], user: user, helpful: true)
      create(:summary_feedback, summary: summaries[1], user: user, helpful: false)
      create(:summary_feedback, summary: summaries[1], user: other_user, helpful: true)
      statements = []
      counter = ->(*, payload) { statements << payload[:sql] if payload[:sql].include?("summary_feedbacks") }
      votes = ActiveSupport::Notifications.subscribed(counter, "sql.active_record") do
        Sources::MyFeedback.new(user.id).fetch(summaries.map(&:id))
      end
      expect(votes).to eq([ true, false, nil ])
      expect(statements.size).to eq(1)
    end
  end
end
