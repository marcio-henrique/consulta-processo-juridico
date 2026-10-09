require "rails_helper"

RSpec.describe "Summary GraphQL operations", type: :graphql do
  let(:number) { "1001399-31.2023.8.26.0070" }
  let(:policy) { Llm::RetryPolicy.new(sleeper: ->(_seconds) { }, logger: Logger.new(nil)) }
  let(:provider) { Llm::Providers::Fake.new }
  let(:client) { Llm::Client.new(provider: provider, model: "fake-v1", policy: policy) }
  let!(:lawsuit) do
    create(:lawsuit, number: number).tap do |record|
      create(:movement, lawsuit: record, occurred_on: Date.new(2024, 1, 10), title: "Distribuição por Sorteio", source_row: 1)
      create(:movement, lawsuit: record, occurred_on: Date.new(2024, 6, 12), title: "Julgada Procedente a Ação",
        content: "Decisão a favor do autor.", source_row: 2)
    end
  end

  let(:latest_query) do
    <<~GQL
      query Lawsuit($number: String!) {
        lawsuit(number: $number) {
          errors { code }
          lawsuit { latestSummary { id body generatedAt } }
        }
      }
    GQL
  end

  let(:mutation) do
    <<~GQL
      mutation GenerateSummary($number: String!) {
        generateSummary(lawsuitNumber: $number) {
          summary { id body generatedAt }
          errors { code message field }
        }
      }
    GQL
  end

  before { allow(Llm::Client).to receive(:build).and_return(client) }

  def latest_summary(value = number)
    execute_graphql(latest_query, variables: { number: value }).dig(:data, :lawsuit, :lawsuit, :latestSummary)
  end

  def generate(value = number)
    execute_graphql(mutation, variables: { number: value })
  end

  describe "Lawsuit.latestSummary" do
    it "is null when nothing was generated and never calls the provider" do
      expect(latest_summary).to be_nil
      expect(Llm::Client).not_to have_received(:build)
      expect(provider.calls).to be_empty
    end

    it "returns the cached summary for the current movements" do
      summary = create(:summary, lawsuit: lawsuit, movements_digest: Summaries::Digest.call(lawsuit.movements),
        prompt_version: Summaries::PromptBuilder::PROMPT_VERSION, body: "Resumo guardado.")

      expect(latest_summary).to include(id: summary.id.to_s, body: "Resumo guardado.", generatedAt: summary.created_at.iso8601)
      expect(provider.calls).to be_empty
    end

    it "is null when the movements changed after the summary was generated" do
      create(:summary, lawsuit: lawsuit, movements_digest: Summaries::Digest.call(lawsuit.movements),
        prompt_version: Summaries::PromptBuilder::PROMPT_VERSION)
      create(:movement, lawsuit: lawsuit, occurred_on: Date.new(2024, 7, 1), title: "Arquivado Definitivamente", source_row: 0)

      expect(latest_summary).to be_nil
    end

    it "is null for an older prompt version" do
      create(:summary, lawsuit: lawsuit, movements_digest: Summaries::Digest.call(lawsuit.movements), prompt_version: "v0")

      expect(latest_summary).to be_nil
    end
  end

  describe "Mutation.generateSummary" do
    it "generates, stores and returns the summary with an empty errors list" do
      payload = generate.dig(:data, :generateSummary)

      expect(payload[:errors]).to eq([])
      expect(payload[:summary][:body]).to include(number)
      expect(payload[:summary][:id]).to eq(Summary.last.id.to_s)
      expect(payload[:summary][:generatedAt]).to be_present
      expect(provider.calls.size).to eq(1)
    end

    it "returns the cached summary on the second call without calling the provider again" do
      first = generate.dig(:data, :generateSummary, :summary)
      second = generate.dig(:data, :generateSummary, :summary)

      expect(second[:id]).to eq(first[:id])
      expect(provider.calls.size).to eq(1)
    end

    it "exposes the generated summary through latestSummary afterwards" do
      generated = generate.dig(:data, :generateSummary, :summary)

      expect(latest_summary).to include(id: generated[:id], body: generated[:body])
    end

    it "accepts the number without punctuation" do
      payload = generate("10013993120238260070").dig(:data, :generateSummary)

      expect(payload[:errors]).to eq([])
      expect(payload[:summary]).to be_present
    end

    it "returns INVALID_CNJ for a bad check digit, without calling the provider" do
      result = generate("1001399-31.2023.8.26.0071")

      expect(result[:errors]).to be_nil
      expect(result.dig(:data, :generateSummary)).to eq(
        summary: nil,
        errors: [ { code: "INVALID_CNJ", message: "Número de processo inválido. Confira os dígitos.", field: "number" } ]
      )
      expect(provider.calls).to be_empty
    end

    it "returns NOT_FOUND for a valid CNJ that is not in the data" do
      payload = generate("1002271-82.2025.8.26.0003").dig(:data, :generateSummary)

      expect(payload[:summary]).to be_nil
      expect(payload[:errors]).to eq([ { code: "NOT_FOUND", message: "Processo não encontrado na base.", field: nil } ])
      expect(provider.calls).to be_empty
    end

    it "returns SUMMARY_UNAVAILABLE with a pt-BR message and no internal details when generation fails" do
      failing = Llm::Providers::Fake.new(failures: Array.new(4) { Llm::ProviderError.new("secret internal detail") })
      allow(Llm::Client).to receive(:build).and_return(Llm::Client.new(provider: failing, model: "fake-v1", policy: policy))

      result = generate

      expect(result[:errors]).to be_nil
      payload = result.dig(:data, :generateSummary)
      expect(payload[:summary]).to be_nil
      expect(payload[:errors]).to eq([ { code: "SUMMARY_UNAVAILABLE", message: "Não foi possível gerar o resumo agora.", field: nil } ])
      expect(result.to_s).not_to include("secret internal detail")
      expect(Summary.count).to eq(0)
    end
  end
end
