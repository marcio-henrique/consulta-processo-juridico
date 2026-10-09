module Llm
  # Retry strategy for one logical LLM call (ADR-0002 decision log):
  # up to 2 retries on the primary model (1 s, then 2 s backoff) for timeout,
  # 429, 500 and 503; then one attempt with the fallback model. The whole call
  # is bounded by a deadline (about 45 s): each attempt receives the smaller of
  # the per-attempt timeout and the remaining budget.
  #
  #   policy.call(primary: "m1", fallback: "m2") { |model, timeout| ... }
  class RetryPolicy
    BACKOFFS = [ 1, 2 ].freeze
    DEADLINE_SECONDS = 45
    DEFAULT_ATTEMPT_TIMEOUT = 20
    MIN_ATTEMPT_SECONDS = 1

    attr_reader :per_attempt_timeout

    def initialize(per_attempt_timeout: DEFAULT_ATTEMPT_TIMEOUT, deadline: DEADLINE_SECONDS,
      backoffs: BACKOFFS, sleeper: Kernel.method(:sleep),
      clock: -> { Process.clock_gettime(Process::CLOCK_MONOTONIC) }, logger: Rails.logger)
      @per_attempt_timeout = per_attempt_timeout
      @deadline = deadline
      @backoffs = backoffs
      @sleeper = sleeper
      @clock = clock
      @logger = logger
    end

    def call(primary:, fallback: nil, &attempt)
      started = @clock.call
      models = Array.new(@backoffs.size + 1) { primary }
      models << fallback if fallback.present? && fallback != primary

      models.each_with_index do |model, index|
        timeout = [ @per_attempt_timeout, remaining(started) ].min
        raise deadline_error if timeout < MIN_ATTEMPT_SECONDS

        begin
          return attempt.call(model, timeout)
        rescue Llm::Error => error
          raise unless error.retryable?
          raise if index == models.size - 1

          @logger.warn("Llm retryable failure attempt=#{index + 1} error=#{error.class}")
          wait(@backoffs[index], started)
        end
      end
    end

    private

    def wait(delay, started)
      return unless delay
      raise deadline_error if remaining(started) - delay < MIN_ATTEMPT_SECONDS

      @sleeper.call(delay)
    end

    def remaining(started)
      @deadline - (@clock.call - started)
    end

    def deadline_error
      Llm::TimeoutError.new("LLM deadline of #{@deadline}s exceeded")
    end
  end
end
