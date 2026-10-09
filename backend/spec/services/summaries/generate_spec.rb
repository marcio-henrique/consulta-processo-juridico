require "rails_helper"

RSpec.describe Summaries::Generate do
  let(:lawsuit) { create(:lawsuit) }
  let(:policy) { Llm::RetryPolicy.new(sleeper: ->(_seconds) { }, logger: Logger.new(nil)) }
  let(:provider) { Llm::Providers::Fake.new }
  let(:client) { Llm::Client.new(provider: provider, model: "fake-v1", fallback_model: "fake-v2", policy: policy) }

  before do
    create(:movement, lawsuit: lawsuit, occurred_on: Date.new(2024, 1, 10), title: "Distribuição por Sorteio", content: nil, source_row: 2)
    create(:movement, lawsuit: lawsuit, occurred_on: Date.new(2024, 3, 5), title: "Julgada Procedente a Ação",
      content: "O juiz decidiu a favor do autor.", source_row: 1)
  end

  def generate(**options)
    described_class.call(lawsuit: lawsuit, client: client, **options)
  end

  def capture_log
    io = StringIO.new
    original = Rails.logger
    Rails.logger = Logger.new(io)
    yield
    io.string
  ensure
    Rails.logger = original
  end

  describe "cache miss" do
    it "calls the provider once and persists the summary with its cache key and usage" do
      result = generate

      expect(result).to be_success
      expect(result.cache_hit).to be(false)
      expect(provider.calls.size).to eq(1)
      expect(result.summary).to have_attributes(
        lawsuit_id: lawsuit.id,
        provider: "fake",
        model: "fake-v1",
        prompt_version: Summaries::PromptBuilder::PROMPT_VERSION,
        movements_digest: Summaries::Digest.call(lawsuit.movements)
      )
      expect(result.summary.body.split("\n\n").size).to be_between(1, 3)
      expect(result.summary.input_tokens).to be > 0
      expect(result.summary.output_tokens).to be > 0
    end

    it "sends the built prompt to the provider with the output token budget" do
      generate

      call = provider.calls.first
      expect(call[:system]).to eq(Summaries::PromptBuilder::SYSTEM_PROMPT)
      expect(call[:user]).to include("Número do processo: #{lawsuit.number}")
      expect(call[:max_output_tokens]).to eq(Summaries::PromptBuilder::MAX_OUTPUT_TOKENS)
    end
  end

  describe "cache" do
    it "returns the stored row without calling the provider again" do
      first = generate
      second = generate

      expect(second.summary).to eq(first.summary)
      expect(second.cache_hit).to be(true)
      expect(provider.calls.size).to eq(1)
      expect(Summary.count).to eq(1)
    end

    it "generates a new summary when the movements change and keeps the old row" do
      first = generate
      create(:movement, lawsuit: lawsuit, occurred_on: Date.new(2024, 4, 1), title: "Arquivado Definitivamente", source_row: 0)

      second = generate

      expect(second.cache_hit).to be(false)
      expect(second.summary).not_to eq(first.summary)
      expect(Summary.count).to eq(2)
      expect(provider.calls.size).to eq(2)
    end

    it "generates a new summary when the prompt version changes" do
      generate
      stub_const("Summaries::PromptBuilder::PROMPT_VERSION", "v2")

      result = generate

      expect(result.cache_hit).to be(false)
      expect(result.summary.prompt_version).to eq("v2")
      expect(Summary.pluck(:prompt_version)).to contain_exactly("v1", "v2")
    end

    it "generates a new summary when the model changes" do
      generate
      other = Llm::Client.new(provider: provider, model: "fake-v9", policy: policy)

      result = described_class.call(lawsuit: lawsuit, client: other)

      expect(result.cache_hit).to be(false)
      expect(Summary.pluck(:model)).to contain_exactly("fake-v1", "fake-v9")
    end

    it "treats a unique violation raised on insert as a cache hit" do
      # Simulates losing the race: the lookups before the insert see nothing,
      # the insert hits the unique index, the re-read finds the winner's row.
      existing = create(:summary, lawsuit: lawsuit, movements_digest: Summaries::Digest.call(lawsuit.movements),
        prompt_version: Summaries::PromptBuilder::PROMPT_VERSION, model: "fake-v1")
      lookups = 0
      allow(Summary).to receive(:find_by).and_wrap_original do |original, *args|
        (lookups += 1) <= 2 ? nil : original.call(*args)
      end
      allow(Summary).to receive(:create!).and_raise(ActiveRecord::RecordNotUnique, "duplicate")

      result = generate

      expect(result).to be_success
      expect(result.cache_hit).to be(true)
      expect(result.summary).to eq(existing)
    end
  end

  describe "failures" do
    def failing_client(errors)
      Llm::Client.new(provider: Llm::Providers::Fake.new(failures: errors), model: "fake-v1", fallback_model: "fake-v2", policy: policy)
    end

    it "returns SUMMARY_UNAVAILABLE and persists nothing when the provider keeps failing" do
      result = described_class.call(lawsuit: lawsuit, client: failing_client(Array.new(4) { Llm::TimeoutError.new }))

      expect(result).not_to be_success
      expect(result.error_code).to eq(:SUMMARY_UNAVAILABLE)
      expect(result.summary).to be_nil
      expect(Summary.count).to eq(0)
    end

    it "maps rate limit and provider errors to SUMMARY_UNAVAILABLE" do
      [ Llm::RateLimitError.new, Llm::ProviderError.new("boom") ].each do |error|
        result = described_class.call(lawsuit: lawsuit, client: failing_client([ error ] * 4))

        expect(result.error_code).to eq(:SUMMARY_UNAVAILABLE)
      end
      expect(Summary.count).to eq(0)
    end

    it "treats a blank answer as a provider failure and persists nothing" do
      blank_client = Llm::Client.new(provider: Llm::Providers::Fake.new(texts: [ "  " ]), model: "fake-v1", policy: policy)

      result = described_class.call(lawsuit: lawsuit, client: blank_client)

      expect(result.error_code).to eq(:SUMMARY_UNAVAILABLE)
      expect(Summary.count).to eq(0)
    end

    it "recovers after a failure on the next attempt" do
      described_class.call(lawsuit: lawsuit, client: failing_client([ Llm::ProviderError.new("boom") ]))

      expect(generate).to be_success
    end

    it "does not hide programming errors" do
      broken = Llm::Client.new(provider: Object.new, model: "m", policy: policy)

      expect { described_class.call(lawsuit: lawsuit, client: broken) }.to raise_error(NoMethodError)
    end
  end

  describe "corrective retry" do
    let(:five_paragraphs) { (1..5).map { |i| "Parágrafo #{i}." }.join("\n\n") }
    let(:good) { "Primeiro parágrafo.\n\nSegundo parágrafo." }

    def client_with(provider)
      Llm::Client.new(provider: provider, model: "fake-v1", policy: policy)
    end

    it "asks once more with a stricter instruction when the answer has more than 3 paragraphs" do
      fake = Llm::Providers::Fake.new(texts: [ five_paragraphs, good ])

      result = described_class.call(lawsuit: lawsuit, client: client_with(fake))

      expect(fake.calls.size).to eq(2)
      expect(fake.calls.last[:user]).to include(described_class::STRICT_INSTRUCTION)
      expect(fake.calls.first[:user]).not_to include(described_class::STRICT_INSTRUCTION)
      expect(result.summary.body).to eq(good)
    end

    it "asks again when the answer is longer than 2,000 characters" do
      fake = Llm::Providers::Fake.new(texts: [ "Frase longa. " * 200, good ])

      result = described_class.call(lawsuit: lawsuit, client: client_with(fake))

      expect(fake.calls.size).to eq(2)
      expect(result.summary.body).to eq(good)
    end

    it "merges and truncates when the retry is still too long" do
      fake = Llm::Providers::Fake.new(texts: [ five_paragraphs, five_paragraphs ])

      result = described_class.call(lawsuit: lawsuit, client: client_with(fake))

      expect(fake.calls.size).to eq(2)
      expect(result.summary.body).to eq("Parágrafo 1.\n\nParágrafo 2.\n\nParágrafo 3. Parágrafo 4. Parágrafo 5.")
    end

    it "enforces the limits on the first answer when the corrective call fails" do
      fake = Llm::Providers::Fake.new(texts: [ five_paragraphs ], failures: [ nil, Llm::ProviderError.new("boom") ])

      result = described_class.call(lawsuit: lawsuit, client: client_with(fake))

      expect(result).to be_success
      expect(result.summary.body.split("\n\n").size).to eq(3)
    end

    it "retries once with the stricter instruction when the answer was cut at the token limit" do
      fake = Llm::Providers::Fake.new(texts: [ good ], failures: [ Llm::TruncatedError.new("max tokens") ])

      result = described_class.call(lawsuit: lawsuit, client: client_with(fake))

      expect(fake.calls.size).to eq(2)
      expect(fake.calls.last[:user]).to include(described_class::STRICT_INSTRUCTION)
      expect(result.summary.body).to eq(good)
    end

    it "gives up with SUMMARY_UNAVAILABLE when the answer is truncated twice" do
      fake = Llm::Providers::Fake.new(failures: [ Llm::TruncatedError.new("1"), Llm::TruncatedError.new("2") ])

      result = described_class.call(lawsuit: lawsuit, client: client_with(fake))

      expect(result.error_code).to eq(:SUMMARY_UNAVAILABLE)
      expect(Summary.count).to eq(0)
    end

    it "adds up token usage across both calls" do
      fake = Llm::Providers::Fake.new(texts: [ five_paragraphs, good ])

      result = described_class.call(lawsuit: lawsuit, client: client_with(fake))

      estimate = ->(call) { ((call[:system].length + call[:user].length) / 4.0).ceil }
      expect(result.summary.input_tokens).to eq(fake.calls.sum(&estimate))
    end
  end

  describe "amount check" do
    let(:good) { "A causa vale R$ 10.000,00.\n\nO juiz decidiu a favor do autor." }
    let(:garbled) { "A causa vale R$ 10,000,00.\n\nO juiz decidiu a favor do autor." }
    let(:invented) { "A causa vale R$ 99.999,00.\n\nO juiz decidiu a favor do autor." }

    def client_with(provider)
      Llm::Client.new(provider: provider, model: "fake-v1", policy: policy)
    end

    it "accepts an amount that is in the prompt without a second call" do
      fake = Llm::Providers::Fake.new(texts: [ good ])

      result = described_class.call(lawsuit: lawsuit, client: client_with(fake))

      expect(fake.calls.size).to eq(1)
      expect(result.summary.body).to eq(good)
    end

    it "asks again when an amount is garbled and stores the corrected answer" do
      fake = Llm::Providers::Fake.new(texts: [ garbled, good ])

      result = described_class.call(lawsuit: lawsuit, client: client_with(fake))

      expect(fake.calls.size).to eq(2)
      expect(fake.calls.last[:user]).to include(described_class::STRICT_INSTRUCTION)
      expect(result.summary.body).to eq(good)
    end

    it "treats an invented amount like a garbled one" do
      fake = Llm::Providers::Fake.new(texts: [ invented, good ])

      expect(described_class.call(lawsuit: lawsuit, client: client_with(fake)).summary.body).to eq(good)
    end

    it "fails with SUMMARY_UNAVAILABLE and persists nothing when the amount is still wrong after the retry" do
      fake = Llm::Providers::Fake.new(texts: [ garbled, invented ])

      result = described_class.call(lawsuit: lawsuit, client: client_with(fake))

      expect(result.error_code).to eq(:SUMMARY_UNAVAILABLE)
      expect(fake.calls.size).to eq(2)
      expect(Summary.count).to eq(0)
    end

    it "fails rather than showing the first answer when the corrective call errors out" do
      fake = Llm::Providers::Fake.new(texts: [ garbled ], failures: [ nil, Llm::ProviderError.new("boom") ])

      result = described_class.call(lawsuit: lawsuit, client: client_with(fake))

      expect(result.error_code).to eq(:SUMMARY_UNAVAILABLE)
      expect(Summary.count).to eq(0)
    end

    it "keeps the first answer (limits enforced) when it was only too long and the retry has a wrong amount" do
      long = (1..5).map { |i| "Parágrafo #{i}." }.join("\n\n")
      fake = Llm::Providers::Fake.new(texts: [ long, garbled ])

      result = described_class.call(lawsuit: lawsuit, client: client_with(fake))

      expect(result).to be_success
      expect(result.summary.body.split("\n\n").size).to eq(3)
    end

    it "does not show wrong amounts after a truncated first answer either" do
      fake = Llm::Providers::Fake.new(texts: [ garbled ], failures: [ Llm::TruncatedError.new("max tokens") ])

      result = described_class.call(lawsuit: lawsuit, client: client_with(fake))

      expect(result.error_code).to eq(:SUMMARY_UNAVAILABLE)
      expect(fake.calls.size).to eq(2)
    end

    it "logs only counts, never the answer text" do
      fake = Llm::Providers::Fake.new(texts: [ garbled, good ])
      log = capture_log { described_class.call(lawsuit: lawsuit, client: client_with(fake)) }

      expect(log).to include("wrong_amounts=1")
      expect(log).not_to include("10,000,00")
    end
  end

  describe "logging and privacy" do
    it "logs provider, model, latency, token counts and cache_hit=false on a miss" do
      log = capture_log { generate }

      expect(log).to match(/Summary generated provider=fake model=fake-v1 latency_ms=\d+ input_tokens=\d+ output_tokens=\d+ cache_hit=false/)
    end

    it "logs cache_hit=true on a hit" do
      generate
      log = capture_log { generate }

      expect(log).to include("cache_hit=true").and include("provider=fake").and include("model=fake-v1")
    end

    it "never logs prompts, movement contents or the summary text" do
      result = nil
      log = capture_log do
        result = generate
        generate
        described_class.call(lawsuit: lawsuit, client: Llm::Client.new(
          provider: Llm::Providers::Fake.new(failures: [ Llm::ProviderError.new("boom") ]), model: "other", policy: policy
        ))
      end

      expect(log).not_to include("O juiz decidiu a favor do autor")
      expect(log).not_to include(result.summary.body)
      expect(log).not_to include("Dados do processo")
      expect(log).not_to include(Summaries::PromptBuilder::SYSTEM_PROMPT[0, 40])
    end

    it "logs a failed generation with the error class and no content" do
      log = capture_log do
        described_class.call(lawsuit: lawsuit, client: Llm::Client.new(
          provider: Llm::Providers::Fake.new(failures: [ Llm::ProviderError.new("boom") ]), model: "m", policy: policy
        ))
      end

      expect(log).to match(/Summary generation failed lawsuit_id=#{lawsuit.id} error=Llm::ProviderError/)
    end
  end

  describe "default client" do
    it "builds the client from the environment (fake provider in tests)" do
      result = described_class.call(lawsuit: lawsuit)

      expect(result).to be_success
      expect(result.summary.provider).to eq("fake")
    end

    it "returns SUMMARY_UNAVAILABLE when the client cannot be built (bad configuration)" do
      allow(Llm::Client).to receive(:build).and_raise(Llm::ProviderError, "Unknown LLM_PROVIDER")

      expect(described_class.call(lawsuit: lawsuit).error_code).to eq(:SUMMARY_UNAVAILABLE)
    end
  end
end

# Real threads need real commits, so these examples opt out of the transactional
# wrapper and clean up after themselves.
RSpec.describe Summaries::Generate, "concurrency" do
  self.use_transactional_tests = false

  let(:policy) { Llm::RetryPolicy.new(sleeper: ->(_seconds) { }, logger: Logger.new(nil)) }

  after do
    Summary.delete_all
    Movement.delete_all
    Lawsuit.delete_all
  end

  it "makes exactly one provider call for two simultaneous requests and returns the same summary" do
    lawsuit = create(:lawsuit)
    create(:movement, lawsuit: lawsuit, title: "Distribuição por Sorteio", source_row: 1)
    provider = Llm::Providers::Fake.new(latency: 0.4)
    client = Llm::Client.new(provider: provider, model: "fake-v1", policy: policy)

    results = 2.times.map do
      Thread.new do
        ActiveRecord::Base.connection_pool.with_connection { described_class.call(lawsuit: Lawsuit.find(lawsuit.id), client: client) }
      end
    end.map(&:value)

    expect(provider.calls.size).to eq(1)
    expect(results.map { |result| result.summary.id }.uniq.size).to eq(1)
    expect(results.map(&:cache_hit)).to contain_exactly(true, false)
    expect(Summary.count).to eq(1)
  end
end
