require "rails_helper"

RSpec.describe Llm::RetryPolicy do
  let(:now) { [ 0.0 ] }
  let(:sleeps) { [] }
  let(:policy) do
    described_class.new(
      per_attempt_timeout: 20,
      sleeper: ->(seconds) { sleeps << seconds; now[0] += seconds },
      clock: -> { now[0] },
      logger: Logger.new(nil)
    )
  end

  # Runs the policy with a script of outcomes (value or exception) per attempt.
  def run(outcomes, fallback: "fallback-model", elapsed_per_failure: 0)
    attempts = []
    result = policy.call(primary: "primary-model", fallback: fallback) do |model, timeout|
      attempts << [ model, timeout ]
      outcome = outcomes.shift
      if outcome.is_a?(Exception)
        now[0] += elapsed_per_failure
        raise outcome
      end
      outcome
    end
    [ result, attempts ]
  end

  it "returns the first successful answer without sleeping" do
    result, attempts = run([ :ok ])

    expect(result).to eq(:ok)
    expect(attempts).to eq([ [ "primary-model", 20 ] ])
    expect(sleeps).to be_empty
  end

  it "retries a timeout twice with 1 s then 2 s backoff before succeeding" do
    result, attempts = run([ Llm::TimeoutError.new, Llm::TimeoutError.new, :ok ])

    expect(result).to eq(:ok)
    expect(attempts.map(&:first)).to eq(%w[primary-model primary-model primary-model])
    expect(sleeps).to eq([ 1, 2 ])
  end

  it "retries rate limit errors and retryable provider errors" do
    result, = run([ Llm::RateLimitError.new, Llm::ProviderError.new("HTTP 503", retryable: true), :ok ])

    expect(result).to eq(:ok)
    expect(sleeps).to eq([ 1, 2 ])
  end

  it "makes one attempt with the fallback model after the retries are exhausted" do
    errors = Array.new(3) { Llm::ProviderError.new("HTTP 503", retryable: true) }
    result, attempts = run(errors + [ :ok ])

    expect(result).to eq(:ok)
    expect(attempts.map(&:first)).to eq(%w[primary-model primary-model primary-model fallback-model])
    expect(sleeps).to eq([ 1, 2 ])
  end

  it "raises the last error when the fallback attempt also fails" do
    errors = Array.new(3) { Llm::TimeoutError.new } + [ Llm::RateLimitError.new("fallback limited") ]

    expect { run(errors) }.to raise_error(Llm::RateLimitError, "fallback limited")
  end

  it "does not retry non-retryable provider errors" do
    expect { run([ Llm::ProviderError.new("HTTP 400") ]) }.to raise_error(Llm::ProviderError, "HTTP 400")
    expect(sleeps).to be_empty
  end

  it "skips the fallback attempt when there is no distinct fallback model" do
    errors = Array.new(3) { Llm::TimeoutError.new }
    attempts = []

    expect do
      policy.call(primary: "same", fallback: "same") do |model, _timeout|
        attempts << model
        raise errors.shift
      end
    end.to raise_error(Llm::TimeoutError)
    expect(attempts.size).to eq(3)
  end

  it "shrinks the per-attempt timeout to the remaining budget and gives up at the 45 s deadline" do
    errors = Array.new(5) { Llm::TimeoutError.new }
    attempts = []

    expect do
      policy.call(primary: "primary-model", fallback: "fallback-model") do |model, timeout|
        attempts << [ model, timeout ]
        now[0] += timeout
        raise errors.shift
      end
    end.to raise_error(Llm::TimeoutError, /deadline/i)

    expect(attempts).to eq([ [ "primary-model", 20 ], [ "primary-model", 20 ], [ "primary-model", 2.0 ] ])
    expect(now[0]).to be <= 45.0
  end

  it "gives up instead of sleeping when the backoff would eat the whole remaining budget" do
    expect do
      run([ Llm::TimeoutError.new, Llm::TimeoutError.new, :ok ], elapsed_per_failure: 44)
    end.to raise_error(Llm::TimeoutError, /deadline/i)
    expect(sleeps).to be_empty
  end
end
