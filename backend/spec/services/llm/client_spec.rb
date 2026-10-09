require "rails_helper"

RSpec.describe Llm::Client do
  describe ".build" do
    # String-keyed ENV pairs arrive as keyword arguments in Ruby 3.
    def build(env = nil, rails_env: "development", **pairs)
      described_class.build(env: (env || {}).merge(pairs), rails_env: rails_env)
    end

    it "uses the fake provider with LLM_PROVIDER=fake" do
      client = build("LLM_PROVIDER" => "fake", "GEMINI_API_KEY" => "k")

      expect(client.provider).to be_a(Llm::Providers::Fake)
      expect(client.model).to eq("fake-v1")
    end

    it "auto selects the fake provider when there is no key" do
      expect(build("LLM_PROVIDER" => "auto").provider).to be_a(Llm::Providers::Fake)
      expect(build({}).provider).to be_a(Llm::Providers::Fake)
      expect(build("GEMINI_API_KEY" => "").provider).to be_a(Llm::Providers::Fake)
    end

    it "auto selects Gemini when the key is present, with the documented model defaults" do
      client = build("GEMINI_API_KEY" => "secret-value")

      expect(client.provider).to be_a(Llm::Providers::Gemini)
      expect(client.model).to eq("gemini-3.5-flash-lite")
      expect(client.fallback_model).to eq("gemini-3.1-flash-lite")
    end

    it "honors LLM_MODEL, LLM_FALLBACK_MODEL and LLM_TIMEOUT_SECONDS" do
      client = build(
        "LLM_PROVIDER" => "gemini", "GEMINI_API_KEY" => "k",
        "LLM_MODEL" => "model-a", "LLM_FALLBACK_MODEL" => "model-b", "LLM_TIMEOUT_SECONDS" => "7"
      )

      expect([ client.model, client.fallback_model ]).to eq(%w[model-a model-b])
      expect(client.policy.per_attempt_timeout).to eq(7)
    end

    it "falls back to the default timeout when LLM_TIMEOUT_SECONDS is invalid" do
      expect(build("LLM_TIMEOUT_SECONDS" => "abc").policy.per_attempt_timeout).to eq(20)
      expect(build("LLM_TIMEOUT_SECONDS" => "0").policy.per_attempt_timeout).to eq(20)
    end

    it "builds Gemini without a key so the app boots; the first call fails clearly" do
      client = build("LLM_PROVIDER" => "gemini")

      expect(client.provider).to be_a(Llm::Providers::Gemini)
      expect { client.complete(system: "s", user: "u", max_output_tokens: 10) }
        .to raise_error(Llm::ProviderError, /GEMINI_API_KEY/)
    end

    it "always uses the fake provider in the test environment" do
      client = build({ "LLM_PROVIDER" => "gemini", "GEMINI_API_KEY" => "k" }, rails_env: "test")

      expect(client.provider).to be_a(Llm::Providers::Fake)
    end

    it "rejects an unknown LLM_PROVIDER" do
      expect { build("LLM_PROVIDER" => "openai") }.to raise_error(Llm::ProviderError, /LLM_PROVIDER/)
    end

    it "defaults to the fake provider under the current (test) Rails environment" do
      expect(described_class.build.provider).to be_a(Llm::Providers::Fake)
    end
  end

  describe "#complete" do
    let(:provider) { Llm::Providers::Fake.new }
    let(:policy) do
      Llm::RetryPolicy.new(sleeper: ->(_seconds) { }, logger: Logger.new(nil))
    end
    let(:client) { described_class.new(provider: provider, model: "m1", fallback_model: "m2", policy: policy) }

    it "returns an Llm::Result from the provider" do
      result = client.complete(system: "sys", user: "Número do processo: 1", max_output_tokens: 100)

      expect(result).to be_a(Llm::Result)
      expect(result.text).to be_present
      expect(result.model).to eq(provider.model)
    end

    it "retries through the policy and passes the fallback model on the last attempt" do
      failing = Llm::Providers::Fake.new(failures: Array.new(3) { Llm::TimeoutError.new })
      client = described_class.new(provider: failing, model: "m1", fallback_model: "m2", policy: policy)

      client.complete(system: "s", user: "u", max_output_tokens: 10)

      expect(failing.calls.map { |call| call[:model] }).to eq(%w[m1 m1 m1 m2])
    end

    it "exposes the provider name" do
      expect(client.provider_name).to eq("fake")
    end
  end
end
