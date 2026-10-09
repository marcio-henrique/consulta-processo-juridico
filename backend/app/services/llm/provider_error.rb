module Llm
  # Any other provider failure: HTTP errors, blocked/safety answers, malformed
  # content or missing configuration. Only 500/503 are marked retryable.
  class ProviderError < Error
    def initialize(message = nil, retryable: false)
      super(message)
      @retryable = retryable
    end

    def retryable?
      @retryable
    end
  end
end
