module Llm
  class RateLimitError < Error
    def retryable?
      true
    end
  end
end
