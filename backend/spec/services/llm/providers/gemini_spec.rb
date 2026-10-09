require "rails_helper"

RSpec.describe Llm::Providers::Gemini do
  let(:api_key) { "AIza-test-key-0123456789" }
  let(:provider) { described_class.new(api_key: api_key) }
  let(:model) { "gemini-test-model" }
  let(:url) { "https://generativelanguage.googleapis.com/v1beta/models/#{model}:generateContent" }

  def ok_body(text: "Resumo de teste.", finish: "STOP", usage: { promptTokenCount: 120, candidatesTokenCount: 30 }, parts: nil)
    {
      candidates: [ { content: { role: "model", parts: parts || [ { text: text } ] }, finishReason: finish } ],
      usageMetadata: usage
    }.to_json
  end

  def stub_gemini(**response)
    stub_request(:post, url).to_return({ headers: { "Content-Type" => "application/json" } }.merge(response))
  end

  def complete(max_output_tokens: 700, timeout: 20)
    provider.complete(model: model, system: "Seja claro.", user: "Dados do processo", max_output_tokens: max_output_tokens, timeout: timeout)
  end

  it "has the provider name gemini" do
    expect(provider.name).to eq("gemini")
  end

  describe "successful answers" do
    it "returns text, model and token counts from usageMetadata" do
      stub_gemini(status: 200, body: ok_body)

      expect(complete).to have_attributes(text: "Resumo de teste.", model: model, input_tokens: 120, output_tokens: 30)
    end

    it "joins several text parts and skips thought parts" do
      parts = [ { text: "pensando", thought: true }, { text: "Primeira." }, { text: " Segunda." } ]
      stub_gemini(status: 200, body: ok_body(parts: parts))

      expect(complete.text).to eq("Primeira. Segunda.")
    end

    it "counts thinking tokens as output tokens" do
      usage = { promptTokenCount: 10, candidatesTokenCount: 20, thoughtsTokenCount: 5 }
      stub_gemini(status: 200, body: ok_body(usage: usage))

      expect(complete.output_tokens).to eq(25)
    end

    it "tolerates a missing usageMetadata" do
      stub_gemini(status: 200, body: { candidates: [ { content: { parts: [ { text: "ok" } ] }, finishReason: "STOP" } ] }.to_json)

      expect(complete).to have_attributes(text: "ok", input_tokens: nil, output_tokens: nil)
    end
  end

  describe "request shape" do
    it "sends the key only in the x-goog-api-key header, never in the URL" do
      stub = stub_request(:post, url).with(headers: { "x-goog-api-key" => api_key })
        .to_return(status: 200, body: ok_body)

      complete

      expect(stub).to have_been_requested
      expect(WebMock::RequestRegistry.instance.requested_signatures.hash.keys.map(&:uri).map(&:to_s))
        .to all(satisfy { |uri| !uri.include?("key=") && !uri.include?(api_key) })
    end

    it "sends system instruction, user content and generation config as JSON" do
      stub = stub_request(:post, url).with do |request|
        body = JSON.parse(request.body)
        request.headers["Content-Type"] == "application/json" &&
          body.dig("systemInstruction", "parts", 0, "text") == "Seja claro." &&
          body.dig("contents", 0, "role") == "user" &&
          body.dig("contents", 0, "parts", 0, "text") == "Dados do processo" &&
          body.dig("generationConfig", "maxOutputTokens") == 321 &&
          body.dig("generationConfig", "temperature") == 0.2
      end.to_return(status: 200, body: ok_body)

      complete(max_output_tokens: 321)

      expect(stub).to have_been_requested
    end
  end

  describe "failures" do
    it "maps HTTP 429 to RateLimitError" do
      stub_gemini(status: 429, body: { error: { message: "quota" } }.to_json)

      expect { complete }.to raise_error(Llm::RateLimitError)
    end

    it "maps HTTP 500 and 503 to retryable ProviderError" do
      [ 500, 503 ].each do |status|
        stub_gemini(status: status, body: { error: { message: "high demand" } }.to_json)

        expect { complete }.to raise_error(Llm::ProviderError) { |error| expect(error).to be_retryable }
      end
    end

    it "maps other HTTP errors to a non-retryable ProviderError" do
      stub_gemini(status: 400, body: { error: { message: "bad request" } }.to_json)

      expect { complete }.to raise_error(Llm::ProviderError, /HTTP 400/) { |error| expect(error).not_to be_retryable }
    end

    it "maps a timeout to TimeoutError" do
      stub_request(:post, url).to_timeout

      expect { complete }.to raise_error(Llm::TimeoutError)
    end

    it "maps a connection failure to a retryable ProviderError" do
      stub_request(:post, url).to_raise(Faraday::ConnectionFailed.new("refused"))

      expect { complete }.to raise_error(Llm::ProviderError) { |error| expect(error).to be_retryable }
    end

    it "rejects a malformed JSON body" do
      stub_gemini(status: 200, body: "<html>oops</html>")

      expect { complete }.to raise_error(Llm::ProviderError, /malformed/i)
    end

    it "rejects an answer without candidates" do
      stub_gemini(status: 200, body: { candidates: [] }.to_json)

      expect { complete }.to raise_error(Llm::ProviderError, /no candidates/i)
    end

    it "rejects a blank answer" do
      stub_gemini(status: 200, body: ok_body(text: "  "))

      expect { complete }.to raise_error(Llm::ProviderError, /empty/i)
    end

    it "treats finishReason SAFETY as a provider error" do
      stub_gemini(status: 200, body: ok_body(text: "x", finish: "SAFETY"))

      expect { complete }.to raise_error(Llm::ProviderError, /SAFETY/) { |error| expect(error).not_to be_retryable }
    end

    it "treats a blocked prompt as a provider error" do
      stub_gemini(status: 200, body: { promptFeedback: { blockReason: "PROHIBITED_CONTENT" } }.to_json)

      expect { complete }.to raise_error(Llm::ProviderError, /blocked/i)
    end

    it "treats finishReason MAX_TOKENS as a truncated answer" do
      stub_gemini(status: 200, body: ok_body(text: "corta", finish: "MAX_TOKENS"))

      expect { complete }.to raise_error(Llm::TruncatedError)
      expect(Llm::TruncatedError.ancestors).to include(Llm::ProviderError)
    end

    it "refuses model ids that could alter the request path" do
      expect do
        provider.complete(model: "../evil?x=", system: "s", user: "u", max_output_tokens: 10, timeout: 5)
      end.to raise_error(Llm::ProviderError, /model/i)
    end
  end

  describe "missing key" do
    it "fails the first call with a clear configuration message and no HTTP request" do
      keyless = described_class.new(api_key: nil)

      expect { keyless.complete(model: model, system: "s", user: "u", max_output_tokens: 10, timeout: 5) }
        .to raise_error(Llm::ProviderError, /GEMINI_API_KEY is not configured/)
      expect(a_request(:any, /./)).not_to have_been_made
    end

    it "treats a blank key as missing" do
      expect { described_class.new(api_key: "  ").complete(model: model, system: "s", user: "u", max_output_tokens: 10, timeout: 5) }
        .to raise_error(Llm::ProviderError, /GEMINI_API_KEY/)
    end
  end

  describe "key hygiene" do
    let(:log) { StringIO.new }
    let(:policy) do
      Llm::RetryPolicy.new(sleeper: ->(_seconds) { }, logger: Logger.new(log))
    end
    let(:client) { Llm::Client.new(provider: provider, model: model, fallback_model: "gemini-fallback", policy: policy) }

    it "never leaks the key into logs or exception messages after failed calls" do
      original = Rails.logger
      Rails.logger = Logger.new(log)
      stub_request(:post, %r{generativelanguage\.googleapis\.com}).to_return(
        { status: 503, body: { error: { message: "high demand #{api_key}" } }.to_json },
        { status: 429, body: "{}" },
        { status: 400, body: { error: { message: "echo #{api_key}" } }.to_json }
      )

      error = begin
        client.complete(system: "s", user: "texto do processo", max_output_tokens: 100)
      rescue Llm::Error => e
        e
      end

      expect(error).to be_a(Llm::ProviderError)
      expect(error.message).not_to include(api_key)
      expect(error.full_message).not_to include(api_key)
      expect(log.string).not_to include(api_key)
      expect(log.string).not_to include("texto do processo")
    ensure
      Rails.logger = original
    end

    it "does not include the key in the inspect output of the provider" do
      expect(provider.inspect).not_to include(api_key)
    end
  end
end
