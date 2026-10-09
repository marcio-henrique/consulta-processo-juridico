module Llm
  # Provider-agnostic facade. Build it from the environment and call #complete;
  # retries, fallback model and deadline are handled by Llm::RetryPolicy.
  #
  #   Llm::Client.build.complete(system: "...", user: "...", max_output_tokens: 700)
  #   # => #<struct Llm::Result text="...", input_tokens=1234, output_tokens=321, model="...">
  class Client
    DEFAULT_MODEL = "gemini-3.5-flash-lite".freeze
    DEFAULT_FALLBACK_MODEL = "gemini-3.1-flash-lite".freeze
    PROVIDERS = %w[auto gemini fake].freeze

    attr_reader :provider, :model, :fallback_model, :policy

    # LLM_PROVIDER: auto (Gemini when GEMINI_API_KEY is set, else Fake), gemini
    # or fake. The test environment always gets Fake; specs inject their own
    # provider through Client.new.
    def self.build(env: ENV, rails_env: Rails.env)
      choice = env["LLM_PROVIDER"].presence || "auto"
      raise ProviderError, "Unknown LLM_PROVIDER (expected auto, gemini or fake)" unless PROVIDERS.include?(choice)

      policy = RetryPolicy.new(per_attempt_timeout: timeout_from(env))
      if fake_selected?(choice, env, rails_env)
        new(provider: Providers::Fake.new, model: Providers::Fake::MODEL, policy: policy)
      else
        new(
          provider: Providers::Gemini.new(api_key: env["GEMINI_API_KEY"]),
          model: env["LLM_MODEL"].presence || DEFAULT_MODEL,
          fallback_model: env["LLM_FALLBACK_MODEL"].presence || DEFAULT_FALLBACK_MODEL,
          policy: policy
        )
      end
    end

    def self.fake_selected?(choice, env, rails_env)
      return true if rails_env.to_s == "test" || choice == "fake"

      choice == "auto" && env["GEMINI_API_KEY"].blank?
    end

    def self.timeout_from(env)
      seconds = env["LLM_TIMEOUT_SECONDS"].to_i
      seconds.positive? ? seconds : RetryPolicy::DEFAULT_ATTEMPT_TIMEOUT
    end
    private_class_method :fake_selected?, :timeout_from

    def initialize(provider:, model:, fallback_model: nil, policy: RetryPolicy.new)
      @provider = provider
      @model = model
      @fallback_model = fallback_model
      @policy = policy
    end

    def provider_name
      provider.name
    end

    def complete(system:, user:, max_output_tokens:)
      policy.call(primary: model, fallback: fallback_model) do |attempt_model, timeout|
        provider.complete(
          model: attempt_model, system: system, user: user,
          max_output_tokens: max_output_tokens, timeout: timeout
        )
      end
    end
  end
end
