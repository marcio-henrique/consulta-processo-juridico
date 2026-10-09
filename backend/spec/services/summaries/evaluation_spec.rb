require "rails_helper"

RSpec.describe Summaries::Evaluation do
  let(:policy) { Llm::RetryPolicy.new(sleeper: ->(_seconds) { }, logger: Logger.new(nil)) }
  let(:provider) { Llm::Providers::Fake.new }
  let(:client) { Llm::Client.new(provider: provider, model: "fake-v1", policy: policy) }
  let(:out) { StringIO.new }
  let!(:lawsuit) do
    create(:lawsuit).tap do |record|
      create(:movement, lawsuit: record, title: "Distribuição por Sorteio", source_row: 1)
      create(:movement, lawsuit: record, title: "Julgada Procedente a Ação", content: "Procedente.", source_row: 2)
    end
  end

  describe "GOLDEN_SET" do
    it "lists valid, distinct CNJ numbers with a reason each" do
      numbers = described_class::GOLDEN_SET.keys

      expect(numbers.size).to eq(10)
      expect(numbers.uniq).to eq(numbers)
      expect(numbers.map { |number| CnjNumber.parse(number) }).to all(be_valid)
      expect(described_class::GOLDEN_SET.values).to all(be_present)
    end

    it "uses a lawsuit whose court really upheld the claim (not an agreement)" do
      expect(described_class::GOLDEN_SET.keys).to include("1004772-13.2022.8.26.0068")
      expect(described_class::GOLDEN_SET.keys).not_to include("1005003-07.2023.8.26.0100")
    end

    it "covers the shortest and the longest lawsuits of the challenge data" do
      expect(described_class::GOLDEN_SET.keys).to include("1019112-71.2025.8.26.0224", "1003790-87.2022.8.26.0071")
    end
  end

  describe ".call" do
    it "prints each summary with tokens, latency and prompt statistics" do
      described_class.call(numbers: [ lawsuit.number ], client: client, out: out, allow_fake: true)

      text = out.string
      expect(text).to include(lawsuit.number)
      expect(text).to include("2 movements")
      expect(text).to match(/tokens in=\d+ out=\d+/)
      expect(text).to match(/latency=\d+ ms/)
      expect(text).to include("model=fake-v1")
      expect(text).to include("O processo #{lawsuit.number}")
    end

    it "reports lawsuits that are not in the database and keeps going" do
      described_class.call(numbers: [ "1002271-82.2025.8.26.0003", lawsuit.number ], client: client, out: out, allow_fake: true)

      expect(out.string).to include("1002271-82.2025.8.26.0003: not found in the database")
      expect(out.string).to include("O processo #{lawsuit.number}")
    end

    it "reports generation failures without stopping" do
      failing = Llm::Client.new(
        provider: Llm::Providers::Fake.new(failures: Array.new(4) { Llm::ProviderError.new("boom") }),
        model: "fake-v1", policy: policy
      )

      described_class.call(numbers: [ lawsuit.number ], client: failing, out: out, allow_fake: true)

      expect(out.string).to include("#{lawsuit.number}: generation failed (SUMMARY_UNAVAILABLE)")
    end

    it "marks answers served from the cache" do
      2.times { described_class.call(numbers: [ lawsuit.number ], client: client, out: out, allow_fake: true) }

      expect(out.string).to include("cache=hit")
      expect(out.string).to include("cache=miss")
    end

    it "refuses to run with the fake provider unless explicitly allowed" do
      expect { described_class.call(numbers: [ lawsuit.number ], client: client, out: out) }
        .to raise_error(described_class::FakeProviderError, /ALLOW_FAKE=1/)
      expect(provider.calls).to be_empty
    end

    it "runs the golden set by default" do
      described_class.call(client: client, out: out, allow_fake: true)

      expect(out.string.scan("not found in the database").size).to eq(described_class::GOLDEN_SET.size)
    end
  end
end
